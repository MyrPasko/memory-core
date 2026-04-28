---
name: memory-audit-skill
description: Audit Memory Core drift, duplicate IDs, stale notes, project-hub alignment, and context minimalism. Use when Aira needs to verify that repo canon and distilled knowledge still agree without growing into broad repo manuals.
---

# Memory Audit Skill

Use this skill periodically and before trusting the memory layer during a new slice.

## Workflow
1. Run:

```bash
./.automation/scripts/aira-memory audit --project <project-slug> --mode project-local
./.automation/scripts/aira-memory audit --project <project-slug> --mode vault-wide
```

2. Treat `project-local` as the hard gate for the two-state authority model:
   - repo project memory is the only active-state store
   - pointer docs and generated summaries must not duplicate active state
3. Use `vault-wide` when cleaning broader Obsidian debt across the whole vault.
4. Read the generated report before deciding whether the memory layer is safe to use.
5. Use `--fail-on-drift` in CI-style or gate-style automation.

## Guardrails
- Drift means repo canon and project hub disagree or the project hub is still legacy format.
- Duplicate IDs are correctness bugs, not cosmetic noise.
- A validated note without a verification date is already stale enough to investigate.
- Prose-heavy canon files and discoverable command duplication are context-hygiene bugs, not harmless style issues.
- In `project-local` mode, missing project hub is policy-controlled and wider vault debt should not block a clean new repo.
