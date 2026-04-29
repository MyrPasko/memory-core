---
task_type: review-closeout
bundle_target: review
---

# Review Closeout Playbook

## Retrieval
- Load the controller-worker contract, workflow, and both implement-result templates.
- Pull failures, decisions, and sessions that mention similar review findings or verification trouble.

## Delivery
- Treat unresolved findings as hard blockers unless explicitly accepted by the controller.
- Require concrete verification evidence in `implement.result.md` and prefer `implement.result.json` for machine-readable closeout fields.
- Use closeout to confirm the slice is actually complete, not merely coded.

## Distillation
- Promote patterns and failures that materially improve future review quality or closeout discipline.
