---
task_type: bugfix
bundle_target: implementation
---

# Bugfix Playbook

## Retrieval
- Load `current-state.md` and `constraints.md`.
- Pull 1-2 failures with matching symptoms or detection paths.
- Pull 1 similar session capsule.
- Pull 1-2 code examples around the failing surface.

## Delivery
- Fix the smallest plausible cause first.
- Preserve existing behavior outside the confirmed bug surface.
- Verify both the fix path and the nearest regression path.

## Distillation
- Capture the failure as first-class knowledge if it exposed a hidden assumption, repeated mistake, or blocked verification path.
