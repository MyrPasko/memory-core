---
task_type: infra
bundle_target: implementation
---

# Infra Playbook

## Retrieval
- Load `constraints.md` and `workflow.md`.
- Pull patterns for workflow, review, verification, or documentation alignment.
- Pull failures tied to toolchain, automation, or drift.

## Delivery
- Keep infra fixes isolated from product behavior.
- Prefer deterministic scripts and documented rules over chat-only conventions.
- Validate on the exact tool boundary affected by the change.

## Distillation
- Promote workflow rules, verification traps, and recovery lessons.
