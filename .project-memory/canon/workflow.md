---
project: memory-core
kind: workflow
---

# Workflow

## Controlled AI-SDLC Loop
1. Use `./.automation/scripts/aira-memory bugfix|feature|infra|investigation|review-closeout` before medium or large tasks.
2. Use `/.claude/agents/aira-controller.md` as the canonical entrypoint for controller-led slices.
3. Generate task context, then approve an explicit plan before any bounded write work starts.
4. Keep active-project truth only in `/.project-memory/canon/current-state.md` and `/.project-memory/verify-commands.md`.
5. Use `./.automation/scripts/aira-memory finish` after implementation or review when durable memory should change.
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
- A slice is incomplete if `implement.result.md` is missing.
- A slice is incomplete if the machine-readable closeout contract is required but `implement.result.json` is missing.
- A slice is incomplete if review-closeout is missing when findings were raised.
- A slice is incomplete if actual file changes escaped the accepted write-scope without explicit approval.
