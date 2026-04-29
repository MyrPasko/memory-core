---
project: memory-core
kind: controller-worker-contract
version: 4
---

# Controller Worker Contract

## Authority Split
- The controller owns task classification, slice selection, plan acceptance, review acceptance, verification judgment, repo canon updates, and commit or promotion decisions.
- The worker owns bounded execution inside the accepted write-scope.
- The reviewer owns finding generation, not final acceptance.
- The memory curator owns extraction and closeout mechanics, not promotion authority.

## Required Accepted Plan Fields
- Exact references
- Write-scope
- Forbidden moves
- Verification surface
- Success criteria
- Slice restrictions

## Worker Rules
- Do not modify files outside the accepted write-scope unless the controller explicitly expands it.
- Do not claim verification results that did not happen.
- Do not update `current-state.md` or `verify-commands.md` unless the accepted task explicitly assigns that responsibility.
- Do not convert candidate memory into durable knowledge without explicit promotion approval.

## Controller Gates
1. Scope gate before decomposition or planning
2. Plan gate before implementation
3. Result and acceptance gate after execution and review
4. Commit and promotion gate after closeout

## Slice Completion Standard
- A slice is incomplete if implementation result logging is missing.
- A slice is incomplete if verification evidence is missing or blocked without explanation.
- A slice is incomplete if controller or reviewer findings remain unresolved without explicit acceptance.
- A slice is incomplete if actual file changes exceed the accepted write-scope.

## Preferred Artifacts
- `/.automation/workspace/context-bundle.md`
- `/.automation/workspace/implement.result.md`
- `/.automation/workspace/implement.result.json`
- `/.automation/workspace/memory-candidates/<task-id>/promotion-review.md`
