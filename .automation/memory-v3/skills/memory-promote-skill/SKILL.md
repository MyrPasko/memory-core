---
name: memory-promote-skill
description: Promote approved Memory V3 candidate artifacts into Obsidian and refresh indexes through an explicit gate. Use when Aira has reviewed candidate notes and wants to publish only the approved subset.
---

# Memory Promote Skill

Use this skill only after candidate knowledge has been reviewed.

## Workflow
1. Prefer the standard wrapper `./.automation/scripts/aira-memory finish` unless you intentionally need manual promotion control.
2. In wrapper apply mode, promotion now requires an explicit review decision. The preferred path is checking entries in `promotion-review.md`.
3. Open the candidate manifest produced by `memory-distill-skill`.
4. Reject one-off patterns, weak decisions, or failures without prevention guidance.
5. Run a dry report first:

```bash
.automation/scripts/promote-memory --manifest <manifest-path>
```

6. Apply only after the report looks correct:

```bash
.automation/scripts/promote-memory \
  --manifest <manifest-path> \
  --apply \
  --refresh-indexes
```

7. Use `--update-project-hub` only when you intentionally want to refresh the generated project hub during manual promotion.

## Guardrails
- Worker output never becomes canon by default.
- Repo canon updates still require a separate controller decision.
- Promotion should fail fast on one-off or contradictory pattern candidates.
