---
name: memory-retrieval-skill
description: Build a task-aware Memory Core context bundle from repo canon, playbooks, Obsidian notes, and live code examples. Use when Aira is preparing context for a worker LLM in a repository that has `/.project-memory/` and the memory scripts installed.
---

# Memory Retrieval Skill

Use this skill when you need a deterministic, minimal context bundle before handing work to the implementation model.

## Workflow
1. Confirm the repository has `/.project-memory/retrieval-map.yaml`.
2. Treat root `AGENTS.md` as a bootstrap pointer only, not as a repo manual.
3. Read the relevant `/.project-memory/canon/` files only if the bundle script is missing or the output looks wrong.
4. Run:

```bash
./.automation/scripts/aira-memory bugfix --query "<bug summary>"
./.automation/scripts/aira-memory feature --query "<feature summary>"
./.automation/scripts/aira-memory investigation --query "<investigation summary>"
```

5. Review `.automation/workspace/context-bundle.md` and the companion manifest before sending context to the worker.
6. Confirm the bundle preferred project-local validated notes and only used cross-project fallback when necessary.
7. If the bundle pulled noisy notes or meta-files, tighten retrieval rules instead of pasting more repo docs manually.

## Guardrails
- Repo canon is authoritative for active-project truth.
- Pull only the playbook and note types mapped for the task type.
- Do not substitute the project hub for repo `current-state.md`.
- Do not load broad stack descriptions or architecture tours into always-on context.
- Do not let `/.project-memory/`, `.automation/workspace/`, or bundle artifacts appear as product code examples unless the task type explicitly allows docs/scripts.
- If the script is unavailable, fall back to the same five-part bundle shape manually:
  - repo canon
  - task playbook
  - relevant patterns
  - relevant failures
  - similar session plus live code examples
