---
project: memory-core
kind: constraints
---

# Constraints

## Process
- Keep PRs narrow and reviewable.
- Never claim verification that did not happen.
- Treat review findings as hard gates.
- Keep controller-owned edits out of worker execution branches unless explicitly intended.

## Memory V3
- Repo canon is operational memory; it must stay short, current, and non-discoverable.
- `/.project-memory/canon/current-state.md` is the only editable active-state store.
- `/.project-memory/verify-commands.md` is the only editable verification-command surface.
- Distilled knowledge belongs in Obsidian note types with frontmatter metadata and explicit lifecycle status.
- Promotion is a separate act from extraction.
- Failures are first-class knowledge, not leftovers hidden inside session prose.
- If a rule can be encoded as a script, check, gate, or generator, do that instead of adding prose.
- Do not duplicate merged baseline, next slice, active risks, or verification reality outside repo project memory.

## Ownership
- Root bootstrap stays minimal and points into `/.project-memory/`; it is not a repo manual.
- Repo canon wins over Obsidian when the two disagree.
- Obsidian project hubs are generated summaries, not active-state documents.
- Worker output never becomes durable memory without an explicit promotion step.
