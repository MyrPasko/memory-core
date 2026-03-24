---
project: memory-core
kind: workflow
---

# Workflow

## Controller / Worker Loop
1. Use `./.automation/scripts/aira-memory bugfix|feature|infra|investigation|review-closeout` before medium or large worker tasks.
2. Hand the worker the bundle plus the approved brief/plan flow.
3. Keep active-project truth only in `/.project-memory/canon/current-state.md` and `/.project-memory/verify-commands.md`.
4. Use `./.automation/scripts/aira-memory finish` after implementation or review when durable memory should change.
5. Treat lower-level scripts as building blocks, not the primary operator path.

## Gates
- Extraction may be automated.
- Promotion is never implicit.
- Repo canon updates require controller approval.
- Audit findings override stale assumptions.
- Pointer-only docs and generated project hubs must never carry active state.
