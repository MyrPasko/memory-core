---
task_type: feature
bundle_target: implementation
---

# Feature Playbook

## Retrieval
- Load the controller-worker contract, constraints, and current state.
- Pull 2-3 patterns that match the feature area or UX/data-flow style.
- Pull 1 similar session capsule.
- Pull 1-2 code examples from the target area.
- Pull failures and landmines only when the task touches a previously fragile area.

## Delivery
- Keep scope to one coherent user-visible or architecture-visible slice.
- Reuse existing contracts and UI or domain patterns before inventing new ones.
- Record the accepted write-scope before implementation starts.
- Verify the narrowest realistic build or test surface for the slice.

## Distillation
- Promote only reusable patterns or meaningful tradeoffs.
- Do not promote one-off implementation details as patterns.
