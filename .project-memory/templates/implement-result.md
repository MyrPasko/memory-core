---
task_id: set-task-id
task_type: feature
status: draft
branch: set-branch
date: 2026-04-27
write_scope: []
forbidden_moves: []
verification_surface: []
success_criteria: []
slice_restrictions: []
---

# Implementation Result

## Structured Sidecar
- If this slice matters, also fill `/.automation/workspace/implement.result.json`.
- The JSON sidecar is the machine-readable contract for verification, write-scope, forbidden moves, and open findings.
- This markdown file remains the human-readable companion, not the only source of closeout truth.

## Plan Summary
- State the accepted slice in one or two sentences.

## Exact References
- List the concrete files, modules, or contracts used as references.

## Write-Scope
- List every file or directory the accepted plan allowed to change.

## Forbidden Moves
- List the areas that were explicitly out of scope.

## Changes Made
- Describe only the implemented changes that actually landed.

## Verification
- `command:` exact command or check name
- `result:` pass | fail | blocked | not-run
- `notes:` concrete evidence, not optimism

## Review Closeout
- Record the findings that were addressed.

## Open Findings
- None

## Distillation Candidates
**Decision**: Example decision
- **Rationale**: Why the choice was made
- **Alternatives considered**: Alternative A, Alternative B
- **Impact**: Main consequence

- **Issue**: Example issue
- **Solution**: What fixed it
- **Prevention**: What should stop the same mistake next time

- **Pattern Name**: Example pattern
- **New Solution**: What approach worked
- **Reusable Insight**: Why this may generalize
