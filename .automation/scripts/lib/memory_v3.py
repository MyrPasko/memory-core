from __future__ import annotations

import fnmatch
import json
import os
import re
import textwrap
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

IGNORED_DIRS = {
    ".git",
    ".angular",
    ".idea",
    ".vscode",
    "node_modules",
    "dist",
    "www",
    "ios",
    "android",
    "output",
}

CODE_EXTENSIONS = {
    ".ts",
    ".tsx",
    ".js",
    ".jsx",
    ".json",
    ".md",
    ".py",
    ".sh",
    ".yaml",
    ".yml",
}

NOTE_DIRS = {
    "Patterns": "Patterns",
    "Failures": "Failures",
    "Decisions": "Decisions",
    "Sessions": "Sessions",
}


@dataclass
class Note:
    path: Path
    note_type: str
    metadata: dict
    body: str
    title: str
    score: float = 0.0
    retrieval_scope: str = ""
    retrieval_status: str = ""


def now_utc_date() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d")


def slugify(value: str) -> str:
    value = value.lower()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    return value.strip("-") or "untitled"


def titleize_slug(value: str) -> str:
    return " ".join(part.capitalize() for part in re.split(r"[-_]+", value) if part)


def sanitize_filename(value: str) -> str:
    cleaned = re.sub(r"[\\/:*?\"<>|]+", "-", value).strip()
    return cleaned or "Untitled"


def load_json_yaml(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def parse_inline_value(raw: str):
    raw = raw.strip()
    if not raw:
        return ""
    if raw[0] in "[{\"" or raw in {"true", "false", "null"} or re.fullmatch(r"-?\d+(\.\d+)?", raw):
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            return raw
    return raw


def parse_frontmatter(text: str) -> tuple[dict, str]:
    if not text.startswith("---\n"):
        return {}, text

    lines = text.splitlines()
    closing_index = None
    for index in range(1, len(lines)):
        if lines[index].strip() == "---":
            closing_index = index
            break

    if closing_index is None:
        return {}, text

    metadata: dict[str, object] = {}
    for line in lines[1:closing_index]:
        if not line.strip() or line.lstrip().startswith("#") or ":" not in line:
            continue
        key, value = line.split(":", 1)
        metadata[key.strip()] = parse_inline_value(value)

    body = "\n".join(lines[closing_index + 1 :]).lstrip("\n")
    return metadata, body


def dump_frontmatter(metadata: dict) -> str:
    lines = ["---"]
    for key, value in metadata.items():
        if isinstance(value, (list, dict, bool, int, float)):
            rendered = json.dumps(value, ensure_ascii=False)
        else:
            rendered = str(value)
        lines.append(f"{key}: {rendered}")
    lines.append("---")
    return "\n".join(lines)


def replace_frontmatter_values(text: str, updates: dict) -> str:
    metadata, body = parse_frontmatter(text)
    metadata.update(updates)
    return f"{dump_frontmatter(metadata)}\n\n{body}".rstrip() + "\n"


def read_markdown(path: Path) -> Note:
    raw = path.read_text(encoding="utf-8")
    metadata, body = parse_frontmatter(raw)
    title = metadata.get("title") or first_heading(body) or path.stem
    title = str(title).replace("-", " ").strip()
    return Note(path=path, note_type=path.parent.name, metadata=metadata, body=body, title=title)


def first_heading(text: str) -> str | None:
    match = re.search(r"^#\s+(.+)$", text, re.MULTILINE)
    return match.group(1).strip() if match else None


def tokenize(text: str) -> list[str]:
    return [token for token in re.findall(r"[a-z0-9]{3,}", text.lower())]


def unique_tokens(text: str) -> set[str]:
    return set(tokenize(text))


def score_text(query_tokens: Iterable[str], text: str, title: str = "") -> float:
    tokens = unique_tokens(text)
    title_tokens = unique_tokens(title)
    score = 0.0
    for token in query_tokens:
        if token in title_tokens:
            score += 5
        if token in tokens:
            score += 2
    if title and " ".join(query_tokens) in title.lower():
        score += 4
    return score


def collect_notes(obsidian_root: Path, note_type: str) -> list[Note]:
    if note_type not in NOTE_DIRS:
        return []

    base = obsidian_root / NOTE_DIRS[note_type]
    if not base.exists():
        return []

    if note_type == "Sessions":
        paths = sorted(base.glob("*/*.md"))
    else:
        paths = sorted(base.glob("*.md"))

    notes: list[Note] = []
    for path in paths:
        if path.name.startswith("."):
            continue
        notes.append(read_markdown(path))
    return notes


def normalize_project_keys(values) -> set[str]:
    if values is None:
        return set()
    if isinstance(values, str):
        candidates = [values]
    elif isinstance(values, (list, tuple, set)):
        candidates = [str(item) for item in values if str(item).strip()]
    else:
        candidates = [str(values)]
    return {slugify(candidate) for candidate in candidates if candidate.strip()}


def note_project_keys(note: Note) -> set[str]:
    keys = set()
    if "project" in note.metadata:
        keys |= normalize_project_keys(note.metadata.get("project"))
    if "projects" in note.metadata:
        keys |= normalize_project_keys(note.metadata.get("projects"))
    return keys


def note_matches_project(note: Note, project_keys: set[str]) -> bool:
    if not project_keys:
        return False
    return bool(note_project_keys(note) & normalize_project_keys(project_keys))


def note_status(note: Note) -> str:
    return str(note.metadata.get("status", "")).strip().lower()


def note_status_label(note: Note) -> str:
    status = note_status(note)
    return status or "legacy-untyped"


def note_last_seen(note: Note) -> str:
    return str(
        note.metadata.get("last_seen_at")
        or note.metadata.get("last_verified_at")
        or note.metadata.get("date")
        or ""
    )


def status_allowed_for_retrieval(status: str, allowed_statuses: set[str]) -> bool:
    if not status:
        return True
    if status in allowed_statuses:
        return True
    return status not in {"candidate", "stale", "deprecated"}


def status_rank(status: str, allowed_statuses: set[str]) -> int:
    if status in allowed_statuses:
        return 0
    if not status:
        return 1
    return 2


def find_project_note_path(obsidian_root: Path, project_slug: str) -> Path:
    projects_root = obsidian_root / "Projects"
    normalized = slugify(project_slug)
    direct = projects_root / project_slug / "Index.md"
    if direct.exists():
        return direct

    for candidate in projects_root.glob("*/Index.md"):
        if slugify(candidate.parent.name) == normalized:
            return candidate

    return projects_root / titleize_slug(project_slug) / "Index.md"


def project_notes(
    obsidian_root: Path,
    note_type: str,
    project_keys: set[str],
    *,
    preferred_statuses: set[str] | None = None,
) -> list[Note]:
    preferred = {item.lower() for item in (preferred_statuses or {"validated"})}
    notes = [note for note in collect_notes(obsidian_root, note_type) if note_matches_project(note, project_keys)]
    notes.sort(
        key=lambda note: (
            note_status(note) not in preferred,
            note_last_seen(note),
            note.title.lower(),
        ),
        reverse=True,
    )
    return notes


def choose_notes(
    obsidian_root: Path,
    note_type: str,
    query: str,
    limit: int,
    *,
    project_keys: set[str] | None = None,
    allowed_statuses: set[str] | None = None,
    prefer_project_match: bool = True,
    cross_project_fallback: bool = True,
) -> list[Note]:
    if limit <= 0:
        return []

    query_tokens = tokenize(query)
    effective_project_keys = project_keys or set()
    effective_statuses = {item.lower() for item in (allowed_statuses or {"validated"})}
    primary_ranked: list[Note] = []
    fallback_ranked: list[Note] = []

    for note in collect_notes(obsidian_root, note_type):
        searchable = f"{json.dumps(note.metadata, ensure_ascii=False)}\n{note.body}"
        note.score = score_text(query_tokens, searchable, note.title)
        if note.score > 0:
            status = note_status(note)
            if not status_allowed_for_retrieval(status, effective_statuses):
                continue
            note.retrieval_status = note_status_label(note)

            if prefer_project_match and note_matches_project(note, effective_project_keys):
                note.retrieval_scope = "project-local"
                primary_ranked.append(note)
                continue

            if cross_project_fallback:
                note.retrieval_scope = "cross-project-fallback"
                fallback_ranked.append(note)

    sort_key = lambda item: (-item.score, status_rank(note_status(item), effective_statuses), item.title.lower())
    primary_ranked.sort(key=sort_key)
    fallback_ranked.sort(key=sort_key)

    selected = primary_ranked[:limit]
    if len(selected) < limit and cross_project_fallback:
        selected.extend(fallback_ranked[: limit - len(selected)])
    return selected[:limit]


def excerpt(text: str, max_chars: int = 700) -> str:
    text = re.sub(r"\n{3,}", "\n\n", text.strip())
    return text[:max_chars].rstrip() + ("..." if len(text) > max_chars else "")


def format_note_entry(note: Note, max_chars: int = 700) -> str:
    body_excerpt = excerpt(note.body, max_chars=max_chars)
    status_line = f"- Status: `{note.retrieval_status}`\n" if note.retrieval_status else ""
    scope_line = f"- Retrieval scope: `{note.retrieval_scope}`\n" if note.retrieval_scope else ""
    return (
        f"### {note.title}\n"
        f"- Path: `{note.path}`\n"
        f"- Score: {note.score:.1f}\n"
        f"{scope_line}"
        f"{status_line}"
        "\n"
        f"{body_excerpt}\n"
    )


def normalize_extensions(extensions: Iterable[str] | None) -> set[str]:
    if not extensions:
        return set(CODE_EXTENSIONS)
    normalized = set()
    for extension in extensions:
        value = str(extension).strip()
        if not value:
            continue
        normalized.add(value if value.startswith(".") else f".{value}")
    return normalized


def path_matches_rules(relative_path: str, patterns: Iterable[str] | None) -> bool:
    for raw_pattern in patterns or []:
        pattern = str(raw_pattern).strip()
        if pattern.startswith("./"):
            pattern = pattern[2:]
        if not pattern:
            continue
        if fnmatch.fnmatch(relative_path, pattern):
            return True
        prefix = pattern.removesuffix("/**").removesuffix("/*").rstrip("/")
        if prefix and (relative_path == prefix or relative_path.startswith(f"{prefix}/")):
            return True
    return False


def iter_code_files(
    repo_root: Path,
    *,
    include_paths: Iterable[str] | None = None,
    exclude_paths: Iterable[str] | None = None,
    allowed_extensions: Iterable[str] | None = None,
) -> Iterable[Path]:
    effective_extensions = normalize_extensions(allowed_extensions)
    for root, dirs, files in os.walk(repo_root):
        dirs[:] = [entry for entry in dirs if entry not in IGNORED_DIRS]
        root_path = Path(root)
        for filename in files:
            path = root_path / filename
            relative_path = path.relative_to(repo_root).as_posix()
            if include_paths and not path_matches_rules(relative_path, include_paths):
                continue
            if exclude_paths and path_matches_rules(relative_path, exclude_paths):
                continue
            if path.suffix in effective_extensions:
                yield path


def find_code_examples(
    repo_root: Path,
    query: str,
    limit: int,
    *,
    include_paths: Iterable[str] | None = None,
    exclude_paths: Iterable[str] | None = None,
    allowed_extensions: Iterable[str] | None = None,
) -> list[dict]:
    if limit <= 0:
        return []
    query_tokens = tokenize(query)
    ranked = []

    for path in iter_code_files(
        repo_root,
        include_paths=include_paths,
        exclude_paths=exclude_paths,
        allowed_extensions=allowed_extensions,
    ):
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        score = score_text(query_tokens, text, str(path))
        if score <= 0:
            continue

        lines = text.splitlines()
        match_index = 0
        for index, line in enumerate(lines):
            lowered = line.lower()
            if any(token in lowered for token in query_tokens):
                match_index = index
                break

        snippet = "\n".join(lines[max(0, match_index - 2) : match_index + 3]).strip()
        ranked.append(
            {
                "path": str(path),
                "relative_path": path.relative_to(repo_root).as_posix(),
                "score": score,
                "snippet": snippet or excerpt(text, max_chars=320),
            }
        )

    ranked.sort(key=lambda item: (-item["score"], item["path"]))
    return ranked[:limit]


def render_template(template_path: Path, mapping: dict[str, str]) -> str:
    text = template_path.read_text(encoding="utf-8")
    for key, value in mapping.items():
        text = text.replace(f"{{{{{key}}}}}", value)
    return text


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def write_text(path: Path, text: str) -> None:
    ensure_parent(path)
    path.write_text(text.rstrip() + "\n", encoding="utf-8")


def write_json(path: Path, data) -> None:
    ensure_parent(path)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def markdown_list(items: Iterable[str], empty: str = "- None") -> str:
    materialized = [item for item in items if item]
    if not materialized:
        return empty
    return "\n".join(f"- {item}" for item in materialized)


def extract_sections(text: str) -> dict[str, str]:
    sections: dict[str, list[str]] = {}
    current = "_preamble"
    sections[current] = []
    for line in text.splitlines():
        heading = re.match(r"^##\s+(.+)$", line.strip())
        if heading:
            current = heading.group(1).strip().lower()
            sections.setdefault(current, [])
            continue
        sections.setdefault(current, []).append(line)
    return {key: "\n".join(value).strip() for key, value in sections.items()}


def render_selected_doc(
    path: Path,
    *,
    sections: list[str] | None = None,
    frontmatter_fields: list[str] | None = None,
    max_chars: int = 800,
) -> str:
    raw = path.read_text(encoding="utf-8")
    metadata, body = parse_frontmatter(raw)
    parsed_sections = extract_sections(body)

    parts = [f"### `{path}`"]
    if frontmatter_fields:
        frontmatter_lines = []
        for field in frontmatter_fields:
            if field in metadata:
                frontmatter_lines.append(f"- `{field}`: {json.dumps(metadata[field], ensure_ascii=False)}")
        if frontmatter_lines:
            parts.extend(frontmatter_lines)

    if sections:
        for section in sections:
            content = parsed_sections.get(section.lower())
            if not content:
                continue
            parts.extend(["", f"#### {section}", excerpt(content, max_chars=max_chars)])
    else:
        parts.extend(["", excerpt(body, max_chars=max_chars)])

    return "\n".join(parts).strip() + "\n"


def query_matches_signals(query: str, signals: list[str]) -> bool:
    lowered = query.lower()
    return any(signal.lower() in lowered for signal in signals)


def file_is_prose_heavy(path: Path, text: str) -> list[str]:
    issues = []
    if len(text) > 2400 or len(text.splitlines()) > 70:
        issues.append(f"{path} is too large for always-on context")

    banned_headings = [
        "## stack",
        "## architecture",
        "## repository guide",
        "## suggested app structure",
        "## product scope",
        "## mission",
    ]
    lowered = text.lower()
    for heading in banned_headings:
        if heading in lowered:
            issues.append(f"{path} contains discoverable repo-manual content via heading `{heading}`")
    return issues


def file_has_discoverable_commands(path: Path, text: str) -> list[str]:
    if path.name == "verify-commands.md":
        return []
    issues = []
    if re.search(r"`?(npm|pnpm|yarn|pytest|cargo|go test|make)\s+", text):
        issues.append(f"{path} contains executable commands outside the dedicated verification surface")
    return issues


def extract_decisions(text: str) -> list[dict]:
    decisions: list[dict] = []
    pattern = re.compile(
        r"\*\*Decision\*\*:\s*(?P<decision>.+?)\n(?:\s*-\s*\*\*Rationale\*\*:\s*(?P<rationale>.+?)\n)?(?:\s*-\s*\*\*Alternatives considered\*\*:\s*(?P<alternatives>.+?)\n)?(?:\s*-\s*\*\*Impact\*\*:\s*(?P<impact>.+?)\n)?",
        re.MULTILINE,
    )
    for match in pattern.finditer(text):
        decisions.append(
            {
                "decision": match.group("decision").strip(),
                "rationale": (match.group("rationale") or "").strip(),
                "alternatives": split_csv(match.group("alternatives") or ""),
                "consequences": split_csv(match.group("impact") or ""),
            }
        )
    return decisions


def extract_issue_triplets(text: str) -> list[dict]:
    pattern = re.compile(
        r"-\s+\*\*Issue\*\*:\s*(?P<issue>.+?)\n-\s+\*\*Solution\*\*:\s*(?P<solution>.+?)\n-\s+\*\*Prevention\*\*:\s*(?P<prevention>.+?)(?:\n|$)",
        re.MULTILINE,
    )
    items = []
    for match in pattern.finditer(text):
        items.append(
            {
                "issue": match.group("issue").strip(),
                "solution": match.group("solution").strip(),
                "prevention": match.group("prevention").strip(),
            }
        )
    return items


def extract_pattern_entries(text: str) -> list[dict]:
    pattern = re.compile(
        r"-\s+\*\*Pattern Name\*\*:\s*(?P<name>.+?)\n-\s+\*\*New Solution\*\*:\s*(?P<solution>.+?)\n-\s+\*\*Reusable Insight\*\*:\s*(?P<insight>.+?)(?:\n|$)",
        re.MULTILINE,
    )
    items = []
    for match in pattern.finditer(text):
        raw_name = match.group("name").strip()
        linked = re.search(r"\[\[(.+?)\]\]", raw_name)
        items.append(
            {
                "name": (linked.group(1) if linked else raw_name).strip(),
                "solution": match.group("solution").strip(),
                "insight": match.group("insight").strip(),
            }
        )
    return items


def split_csv(raw: str) -> list[str]:
    if not raw.strip():
        return []
    parts = [part.strip(" .") for part in re.split(r",|;|\n", raw) if part.strip()]
    return parts


def summary_from_text(text: str, limit: int = 3) -> list[str]:
    lines = []
    for raw in text.splitlines():
        line = raw.strip()
        if not line:
            continue
        if line.startswith("#"):
            continue
        line = re.sub(r"^[-*+]\s+", "", line)
        line = re.sub(r"^\d+\.\s+", "", line)
        line = re.sub(r"\*\*(.+?)\*\*", r"\1", line)
        if len(line) < 12:
            continue
        lines.append(line)
        if len(lines) >= limit:
            break
    return lines


def detect_verification(text: str) -> dict:
    lowered = text.lower()
    checks = {
        "build": "unknown",
        "typecheck": "unknown",
        "lint": "unknown",
        "tests": "unknown",
    }
    for name in list(checks):
        if f"{name}: pass" in lowered or f"{name} passes" in lowered or f"{name} passed" in lowered:
            checks[name] = "pass"
        elif f"{name}: fail" in lowered or f"{name} failed" in lowered:
            checks[name] = "fail"
        elif "blocked" in lowered and name in lowered:
            checks[name] = "blocked"
    return checks


def maybe_quote(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def format_code_examples(examples: list[dict]) -> str:
    if not examples:
        return "No code examples found."
    blocks = []
    for example in examples:
        blocks.append(
            f"### `{example['path']}`\n"
            f"- Score: {example['score']:.1f}\n\n"
            f"```text\n{example['snippet']}\n```"
        )
    return "\n\n".join(blocks)


def rebuild_indexes(obsidian_root: Path) -> dict[str, Path]:
    indexes_root = obsidian_root / "Indexes"
    indexes_root.mkdir(parents=True, exist_ok=True)

    session_notes = collect_notes(obsidian_root, "Sessions")
    session_notes.sort(key=lambda note: str(note.metadata.get("date", note.path.parent.name)), reverse=True)
    sessions_content = "# Sessions Index\n\n" + markdown_list(
        [
            f"{note.metadata.get('date', note.path.parent.name)} [[{note.path.stem}]]"
            for note in session_notes
        ]
    )
    write_text(indexes_root / "Sessions.md", sessions_content)

    for note_type, filename in [("Patterns", "Patterns.md"), ("Failures", "Failures.md"), ("Decisions", "Decisions.md")]:
        notes = collect_notes(obsidian_root, note_type)
        notes.sort(key=lambda note: note.title.lower())
        content = f"# {note_type} Index\n\n" + markdown_list([f"[[{note.path.stem}]]" for note in notes])
        write_text(indexes_root / filename, content)

    counts = {
        note_type.lower(): len(collect_notes(obsidian_root, note_type))
        for note_type in ("Patterns", "Failures", "Decisions", "Sessions")
    }
    latest_sessions = collect_notes(obsidian_root, "Sessions")
    latest_sessions.sort(key=lambda note: str(note.metadata.get("date", note.path.parent.name)), reverse=True)
    latest_block = markdown_list([f"[[{note.path.stem}]]" for note in latest_sessions[:5]])
    kb_content = (
        "# Knowledge Base Index\n\n"
        "## Summary\n"
        f"- Patterns: {counts['patterns']}\n"
        f"- Failures: {counts['failures']}\n"
        f"- Decisions: {counts['decisions']}\n"
        f"- Sessions: {counts['sessions']}\n\n"
        "## Latest Sessions\n"
        f"{latest_block}\n\n"
        "## Navigation\n"
        "- [[Indexes/Patterns]]\n"
        "- [[Indexes/Failures]]\n"
        "- [[Indexes/Decisions]]\n"
        "- [[Indexes/Sessions]]\n"
        "- [[Index]]\n"
    )
    write_text(indexes_root / "KnowledgeBase.md", kb_content)

    return {
        "sessions": indexes_root / "Sessions.md",
        "patterns": indexes_root / "Patterns.md",
        "failures": indexes_root / "Failures.md",
        "decisions": indexes_root / "Decisions.md",
        "knowledge_base": indexes_root / "KnowledgeBase.md",
    }


def build_project_hub_text(
    template_path: Path,
    project: str,
    repo_path: str,
    repo_canon_path: str,
    latest_sessions: list[str],
    key_patterns: list[str],
    recent_failures: list[str],
    recent_decisions: list[str],
    ) -> str:
    return render_template(
        template_path,
        {
            "project": project,
            "repo_path": repo_path,
            "repo_canon_path": repo_canon_path,
            "title": titleize_slug(project),
            "latest_sessions_json": json.dumps(latest_sessions, ensure_ascii=False),
            "key_patterns_json": json.dumps(key_patterns, ensure_ascii=False),
            "recent_failures_json": json.dumps(recent_failures, ensure_ascii=False),
            "recent_decisions_json": json.dumps(recent_decisions, ensure_ascii=False),
            "latest_sessions": markdown_list([f"[[{item}]]" for item in latest_sessions]),
            "key_patterns": markdown_list([f"[[{item}]]" for item in key_patterns]),
            "recent_failures": markdown_list([f"[[{item}]]" for item in recent_failures]),
            "recent_decisions": markdown_list([f"[[{item}]]" for item in recent_decisions]),
        },
    )


def build_project_hub_text_for_project(
    *,
    template_path: Path,
    obsidian_root: Path,
    project: str,
    repo_path: str,
    repo_canon_path: str,
) -> str:
    project_keys = normalize_project_keys([project, Path(repo_path).name])
    sessions = project_notes(obsidian_root, "Sessions", project_keys)
    patterns = project_notes(obsidian_root, "Patterns", project_keys)
    failures = project_notes(obsidian_root, "Failures", project_keys)
    decisions = project_notes(obsidian_root, "Decisions", project_keys)

    return build_project_hub_text(
        template_path=template_path,
        project=project,
        repo_path=repo_path,
        repo_canon_path=repo_canon_path,
        latest_sessions=[note.path.stem for note in sessions[:5]],
        key_patterns=[note.title for note in patterns[:5]],
        recent_failures=[note.title for note in failures[:5]],
        recent_decisions=[note.title for note in decisions[:5]],
    )


def legacy_or_missing_project_hub(project_note: Path) -> bool:
    if not project_note.exists():
        return True
    metadata, _ = parse_frontmatter(project_note.read_text(encoding="utf-8"))
    return metadata.get("summary_mode") != "v2"


def wrap(text: str) -> str:
    return "\n".join(textwrap.wrap(text, width=88))
