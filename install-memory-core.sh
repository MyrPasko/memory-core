#!/usr/bin/env bash

set -euo pipefail

BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD_DIR="$BUNDLE_DIR/payload"

TARGET=""
SYNC_GLOBAL_SKILLS="false"
SYNC_OBSIDIAN="false"
INSTALL_ADAPTERS="false"

usage() {
  cat <<'EOF'
Usage:
  ./install-memory-core.sh --target /absolute/path/to/project [--sync-global-skills] [--sync-obsidian] [--install-adapters]

Options:
  --target <path>        Target repository path
  --sync-global-skills   Install memory skills into ~/.codex/skills
  --sync-obsidian        Install index/templates into ~/obsidian/main/CODEX_AIRA
  --install-adapters     Install optional provider adapter assets alongside global skills
  -h, --help             Show this help
EOF
}

resolve_payload_dir() {
  if [[ -d "$PAYLOAD_DIR/.project-memory" && -d "$PAYLOAD_DIR/.automation" ]]; then
    printf '%s\n' "$PAYLOAD_DIR"
    return 0
  fi

  if [[ -d "$BUNDLE_DIR/.project-memory" && -d "$BUNDLE_DIR/.automation" ]]; then
    printf '%s\n' "$BUNDLE_DIR"
    return 0
  fi

  echo "Unable to locate payload assets next to installer: $BUNDLE_DIR" >&2
  echo "Expected either payload/.project-memory + payload/.automation or source repo .project-memory + .automation." >&2
  exit 1
}

backup_if_exists() {
  local path="$1"
  if [[ -e "$path" ]]; then
    local backup="${path}.bak.$(date +%Y%m%d-%H%M%S)"
    mv "$path" "$backup"
    printf 'backed_up=%s\n' "$backup"
  fi
}

copy_tree() {
  local source="$1"
  local destination="$2"
  mkdir -p "$(dirname "$destination")"
  backup_if_exists "$destination"
  cp -R "$source" "$destination"
}

render_minimal_templates() {
  local target_root="$1"
  local project_name
  local today
  project_name="$(basename "$target_root")"
  today="$(date +%F)"

  mkdir -p "$target_root/.project-memory/canon"

  cat >"$target_root/AGENTS.md" <<EOF
# Aira Bootstrap

Use this file as a bootstrap only. Do not treat it as the project manual.

## Load Next
- \`/.project-memory/canon/constraints.md\`
- \`/.project-memory/canon/controller-worker-contract.md\`
- \`/.project-memory/canon/workflow.md\`
- \`/.project-memory/canon/current-state.md\`
- \`/.project-memory/canon/repo-landmines.md\`
- \`/.project-memory/verify-commands.md\` for exact verification commands
- \`/.project-memory/docs-index.md\` for version-matched docs pointers

## Critical Landmines
- Repo project memory is authoritative over Obsidian and generated summaries when they disagree.
- Agents are useful because their authority is limited.
- Do not promote memory artifacts automatically after extraction.
- Greenfield installation records only zero-state facts until real project truth is written.

## Rule
- If knowledge is discoverable from code, config, scripts, or local docs, it does not belong in this bootstrap file.
EOF

  cat >"$target_root/.project-memory/canon/repo-landmines.md" <<EOF
---
kind: repo-landmines
project: $project_name
authoritative_since: $today
---

# Repo Landmines

## Critical Landmines
- Repo project memory is authoritative over Obsidian and generated summaries when they disagree.
- Worker output becomes durable knowledge only after extraction plus explicit promotion.
- This repository is still in greenfield mode until project-specific landmines are recorded.
- Do not widen an accepted slice without controller approval and updated write-scope.

## Do Not Infer From Code Alone
- No implementation files means no stack, subsystem, or deployment model is established yet.
- Verification success must come from real commands and real runs, not from installation defaults.
- Add only the hidden invariants, risky zones, or deprecated paths that repeatedly cause errors.
EOF

  cat >"$target_root/.project-memory/canon/current-state.md" <<EOF
---
project: $project_name
merged_baseline: repository-initialized-no-implementation
next_slice: unassigned
active_risks: ["project-memory-not-yet-specialized"]
verification_reality: ["no-verification-commands-curated-yet"]
authoritative_since: $today
---

# Current State

## Merged Baseline
- The repository exists, but no implementation baseline has been recorded into project memory yet.

## Next Slice
- No slice is assigned yet.

## Active Risks
- Greenfield defaults are still in place. Replace them with real risks as soon as the first task is defined.

## Verification Reality
- No exact verification commands are curated yet. Do not imply successful verification until \`/.project-memory/verify-commands.md\` is filled with real commands.
EOF

  cat >"$target_root/.project-memory/canon/constraints.md" <<EOF
---
project: $project_name
kind: constraints
---

# Constraints

## Process
- Keep PRs narrow and reviewable.
- Never claim verification that did not happen.
- Treat review findings as hard gates.
- Keep controller-owned decisions out of worker execution unless explicitly included in the accepted plan.
- Agents are useful because their authority is limited.

## Memory Core
- Repo canon is operational memory; it must stay short, current, and non-discoverable.
- \`/.project-memory/canon/current-state.md\` is the only editable active-state store.
- \`/.project-memory/verify-commands.md\` is the only editable verification-command surface.
- Distilled knowledge belongs in note artifacts with explicit lifecycle status.
- Promotion is a separate act from extraction.
- Failures are first-class knowledge, not leftovers hidden inside session prose.
- If a rule can be encoded as a script, check, gate, or generator, do that instead of adding prose.
- Do not duplicate merged baseline, next slice, active risks, or verification reality outside repo project memory.

## Ownership
- Root bootstrap stays minimal and points into \`/.project-memory/\`; it is not a repo manual.
- Repo canon wins over Obsidian and generated project hubs when they disagree.
- Project hubs are generated summaries, not active-state documents.
- Worker output never becomes durable memory without an explicit promotion step.
EOF

  cat >"$target_root/.project-memory/canon/workflow.md" <<EOF
---
project: $project_name
kind: workflow
---

# Workflow

## Controlled AI-SDLC Loop
1. Use \`./.automation/scripts/aira-memory bugfix|feature|infra|investigation|review-closeout\` before medium or large tasks.
2. Use \`/.claude/agents/aira-controller.md\` as the canonical entrypoint for controller-led slices.
3. Generate task context, then approve an explicit plan before any bounded write work starts.
4. Keep active-project truth only in \`/.project-memory/canon/current-state.md\` and \`/.project-memory/verify-commands.md\`.
5. Use \`./.automation/scripts/aira-memory finish\` after implementation or review when durable memory should change.
6. Treat lower-level scripts as building blocks, not the primary operator path.

## Gates
- Task classification comes before implementation.
- Large tasks may require decomposition into ordered slices.
- Accepted plans must define exact references, write-scope, forbidden moves, verification surface, success criteria, and slice restrictions.
- Extraction may be automated.
- Promotion is never implicit.
- Repo canon updates require controller approval.
- Audit findings override stale assumptions.
- Pointer-only docs and generated project hubs must never carry active state.

## Slice Completion
- A slice is incomplete if verification is missing.
- A slice is incomplete if \`implement.result.md\` is missing.
- A slice is incomplete if review-closeout is missing when findings were raised.
- A slice is incomplete if actual file changes escaped the accepted write-scope without explicit approval.
EOF

  cat >"$target_root/.project-memory/verify-commands.md" <<'EOF'
---
kind: verification-commands
version: 4
---

# Verification Commands

## Frontend
- No frontend verification commands are registered yet.

## Backend
- No backend verification commands are registered yet.

## Notes
- Add only commands that are real, repeatable, and already supported by this repository.
- Until commands are curated here, do not imply green verification.
EOF

  cat >"$target_root/.project-memory/docs-index.md" <<'EOF'
---
kind: docs-index
version: 4
---

# Docs Index

## Framework Docs
- None registered yet.

## Local Docs
- None registered yet.

## Retrieval Rule
- Add only version-specific, non-obvious documentation pointers that the worker cannot recover reliably from code and config alone.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET="${2:?missing value for --target}"
      shift 2
      ;;
    --sync-global-skills)
      SYNC_GLOBAL_SKILLS="true"
      shift
      ;;
    --sync-obsidian)
      SYNC_OBSIDIAN="true"
      shift
      ;;
    --install-adapters)
      INSTALL_ADAPTERS="true"
      SYNC_GLOBAL_SKILLS="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  usage >&2
  exit 1
fi

if [[ ! -d "$TARGET" ]]; then
  echo "Target directory does not exist: $TARGET" >&2
  exit 1
fi

TARGET="$(cd -P -- "$TARGET" && pwd -P)"

if [[ ! -d "$TARGET/.git" ]]; then
  echo "Target does not look like a git repository: $TARGET" >&2
  exit 1
fi

PAYLOAD_DIR="$(resolve_payload_dir)"

copy_tree "$PAYLOAD_DIR/.project-memory" "$TARGET/.project-memory"
copy_tree "$PAYLOAD_DIR/.automation" "$TARGET/.automation"

if [[ -d "$PAYLOAD_DIR/.claude/agents" ]]; then
  copy_tree "$PAYLOAD_DIR/.claude/agents" "$TARGET/.claude/agents"
fi

find "$TARGET/.project-memory" -name '._*' -delete
find "$TARGET/.automation" -name '._*' -delete
find "$TARGET/.claude" -name '._*' -delete 2>/dev/null || true

find "$TARGET/.automation/scripts" -maxdepth 1 -type f -exec chmod +x {} +

render_minimal_templates "$TARGET"

if [[ "$SYNC_GLOBAL_SKILLS" == "true" ]]; then
  mkdir -p "$HOME/.codex/skills"
  copy_tree "$PAYLOAD_DIR/.automation/memory-v3/skills/memory-retrieval-skill" "$HOME/.codex/skills/memory-retrieval-skill"
  copy_tree "$PAYLOAD_DIR/.automation/memory-v3/skills/memory-distill-skill" "$HOME/.codex/skills/memory-distill-skill"
  copy_tree "$PAYLOAD_DIR/.automation/memory-v3/skills/memory-promote-skill" "$HOME/.codex/skills/memory-promote-skill"
  copy_tree "$PAYLOAD_DIR/.automation/memory-v3/skills/memory-audit-skill" "$HOME/.codex/skills/memory-audit-skill"
  copy_tree "$PAYLOAD_DIR/.automation/memory-v3/skills/memory-operator-skill" "$HOME/.codex/skills/memory-operator-skill"
  copy_tree "$PAYLOAD_DIR/.automation/memory-v3/skills/agent-surface-integration-skill" "$HOME/.codex/skills/agent-surface-integration-skill"
fi

if [[ "$SYNC_OBSIDIAN" == "true" ]]; then
  local_obsidian="$HOME/obsidian/main/CODEX_AIRA"
  mkdir -p "$local_obsidian/Indexes" "$local_obsidian/Tools" "$local_obsidian/Projects/_Templates" "$local_obsidian/Failures" "$local_obsidian/Decisions"
  copy_tree "$PAYLOAD_DIR/.automation/memory-v3/obsidian/Index.md" "$local_obsidian/Index.md"
  copy_tree "$PAYLOAD_DIR/.automation/memory-v3/obsidian/Indexes/KnowledgeBase.md" "$local_obsidian/Indexes/KnowledgeBase.md"
  copy_tree "$PAYLOAD_DIR/.automation/memory-v3/obsidian/Indexes/Failures.md" "$local_obsidian/Indexes/Failures.md"
  copy_tree "$PAYLOAD_DIR/.automation/memory-v3/obsidian/Indexes/Decisions.md" "$local_obsidian/Indexes/Decisions.md"
  copy_tree "$PAYLOAD_DIR/.automation/memory-v3/obsidian/Tools/Memory-System-V3.md" "$local_obsidian/Tools/Memory-System-V3.md"
  copy_tree "$PAYLOAD_DIR/.automation/memory-v3/obsidian/Projects/_Templates/Project-Hub-V3.md" "$local_obsidian/Projects/_Templates/Project-Hub-V3.md"
fi

cat <<EOF
installed_target=$TARGET
operator_cli=.automation/scripts/aira-memory
controller_agent=.claude/agents/aira-controller.md
sync_global_skills=$SYNC_GLOBAL_SKILLS
sync_obsidian=$SYNC_OBSIDIAN
install_adapters=$INSTALL_ADAPTERS
update_after_install=AGENTS.md,.project-memory/canon/repo-landmines.md,.project-memory/canon/current-state.md,.project-memory/verify-commands.md,.project-memory/docs-index.md
EOF
