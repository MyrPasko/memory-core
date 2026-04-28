---
name: memory-distill-skill
description: Extract candidate session capsules, patterns, failures, and decisions from completed task artifacts without promoting them automatically. Use when Aira has implementation/review outputs and wants Memory Core candidates in `.automation/workspace/memory-candidates/`.
---

# Memory Distill Skill

Use this skill after a worker pass, review pass, or closeout session when new knowledge may have been produced.

## Workflow
1. Gather the task artifacts that contain real outcomes: implementation summary, review notes, verification notes, or session notes.
2. Prefer the standard wrapper:

```bash
./.automation/scripts/aira-memory finish --task-id <task-id>
```

Use explicit flags only when the defaults are wrong:

```bash
./.automation/scripts/aira-memory finish --task-id <task-id> --task-type <type> --input <artifact-path>
```

3. Review the generated `promotion-review.md`, then rerun with `--apply`.
4. Use the low-level extractor directly only when you are debugging or intentionally splitting extraction from promotion:

```bash
.automation/scripts/extract-memory-candidates \
  --project <project-slug> \
  --task-id <task-id> \
  --task-type <type> \
  --input <artifact-path>
```

5. Inspect the generated candidate manifest and report under `.automation/workspace/memory-candidates/<task-id>/`.
6. Treat the output as candidate knowledge only.

## Guardrails
- Distillation is not promotion.
- Prefer explicit session evidence over chat recollection.
- If the artifacts do not show a reusable lesson, allow zero pattern candidates.
- Failures are valid knowledge outputs; do not suppress them because they are uncomfortable.
