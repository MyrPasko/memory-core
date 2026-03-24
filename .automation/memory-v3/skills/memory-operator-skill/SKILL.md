---
name: memory-operator-skill
description: Operate Memory V3 through the human-facing `./.automation/scripts/aira-memory` wrapper instead of low-level scripts. Use when Aira or another LLM needs to prepare worker context, close the memory loop, audit memory health, or rebuild the generated project hub in a repository with Memory V3 installed.
---

# Memory Operator Skill

Use this skill as the default operator interface for Memory V3.

## Workflow
1. Prefer `./.automation/scripts/aira-memory` over direct low-level script calls.
2. Use:

```bash
./.automation/scripts/aira-memory bugfix --query "<bug summary>"
./.automation/scripts/aira-memory feature --query "<feature summary>"
./.automation/scripts/aira-memory finish --task-id <task-id>
./.automation/scripts/aira-memory audit --mode project-local
./.automation/scripts/aira-memory rebuild-hub
```

3. For closeout, run `./.automation/scripts/aira-memory finish` once to generate `promotion-review.md`.
4. Review the checked items, then rerun with `--apply`.
5. Use low-level scripts only when debugging or when the wrapper lacks a needed flag.

## Guardrails
- `./.automation/scripts/aira-memory` is an operator surface, not a second memory store.
- Repo project memory remains the only active-state authority.
- Obsidian remains distilled knowledge only.
- Promotion is explicit; do not auto-promote artifacts without review.
- If the wrapper output looks wrong, fix retrieval rules or repo canon instead of compensating with ad-hoc prompt context.
