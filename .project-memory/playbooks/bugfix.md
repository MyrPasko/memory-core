---
task_type: bugfix
bundle_target: implementation
---

# Bugfix Playbook

## Retrieval
- Load the controller-worker contract, current state, and verification commands.
- Pull failures first, then patterns only if they actually map to the defect area.
- Prefer local references and regression-sensitive landmines over broad code tours.

## Delivery
- Keep the fix narrow enough to explain the regression boundary.
- Record the accepted write-scope before implementation starts.
- Verify the smallest command surface that proves the regression is addressed.

## Distillation
- Promote repeated failure modes and prevention guidance.
- Avoid turning a one-time cleanup into permanent process prose.
