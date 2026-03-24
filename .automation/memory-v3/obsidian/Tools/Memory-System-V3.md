# Memory System V3

## Purpose
- Keep active-project truth only in repo project memory.
- Keep distilled reusable knowledge in Obsidian.
- Make retrieval explicit and closeout one-command by default.
- Keep root bootstrap context minimal and pointer-based.
- Prefer project-local validated notes before cross-project fallback.

## Required Note Types
- `Sessions/` for session capsules
- `Patterns/` for reusable solutions
- `Failures/` for anti-patterns and regression traps
- `Decisions/` for tradeoffs and rationale

## Required Repo Surfaces
- `./.automation/scripts/aira-memory`
- `/.project-memory/canon/`
- `/.project-memory/verify-commands.md`
- `/.project-memory/playbooks/`
- `/.project-memory/retrieval-map.yaml`
- `/.project-memory/memory-contract.yaml`
- `.automation/scripts/build-context-bundle`
- `.automation/scripts/close-memory-loop`
- `.automation/scripts/rebuild-project-hub`
- `.automation/scripts/extract-memory-candidates`
- `.automation/scripts/promote-memory`
- `.automation/scripts/audit-memory`

## Rule
- `/.project-memory/canon/current-state.md` is the only editable active-state store.
- `/.project-memory/verify-commands.md` is the only editable verification-command surface.
- Distillation is automatic-friendly.
- Promotion is explicit, and wrapper apply mode now requires `promotion-review.md`, `--approve-all`, or repeated `--approve-id`.
- Repo canon wins when repo and Obsidian disagree.
- Project hub and indexes are generated summaries, not manual state files.
- Discoverable repo facts should live in code, config, scripts, or local docs, not in always-on context.
- Use `audit-memory --mode project-local` for repo gating and `--mode vault-wide` for whole-vault cleanup.
- Fresh installs should fail strict audit until `current-state.md` and `verify-commands.md` are filled with real project values.
- Prefer `./.automation/scripts/aira-memory` as the operator interface; the lower-level scripts remain internal building blocks and debugging tools.
