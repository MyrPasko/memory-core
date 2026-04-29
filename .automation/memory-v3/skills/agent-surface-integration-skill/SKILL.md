---
name: agent-surface-integration-skill
description: Rewrite an existing repo-owned Claude agent and skill surface into compact text artifacts and a routing contract that Aira agents can load safely. Use when a repository already has `.claude/agents` or `.claude/skills` content and Aira needs a deterministic integration layer instead of guessing how to route across existing agents, existing skills, and Aira governance roles.
---

# Agent Surface Integration Skill

Use this skill when a repository already owns a Claude agent or skill surface and Aira needs a deterministic integration layer.

## Workflow
1. Confirm the repository already has a meaningful `/.claude/agents/` or `/.claude/skills/` surface.
2. Prefer the deterministic script over manual summarization:

```bash
./.automation/scripts/integrate-agent-surface
```

3. If the repo keeps skills outside `/.claude/skills/`, include them explicitly:

```bash
./.automation/scripts/integrate-agent-surface --skill-dir path/to/repo-skills
```

4. Review the generated artifacts under `/.project-memory/integrations/agent-routing/`:
- `integration-brief.md`
- `routing-contract.md`
- `existing-agents.md`
- `existing-skills.md`
- `inventory.json`

5. Treat `routing-contract.md` as the required handoff surface for Aira controller and planner before repo-owned agents or skills participate in delivery.
6. Re-run the script after adding, removing, or materially changing repo-owned agents or skills.

## Routing Contract
- Aira controller, reviewer, and memory roles keep governance authority.
- Repo-owned skills are deterministic helpers and should be preferred for procedural subtasks.
- Repo-owned agents may be used as bounded domain helpers only after the Aira plan is fixed.
- If a repo-owned surface looks like a controller, planner, reviewer, or executor, treat it as a collision-risk helper instead of a replacement governance role unless a human explicitly approves otherwise.
- Repo canon always wins when repo-owned agent or skill instructions disagree with Memory Core governance.

## Guardrails
- Do not manually rewrite a large agent tree if the script can generate the artifacts deterministically.
- Do not let repo-owned agents override accepted write-scope, verification gates, or closeout authority.
- Do not store the routing contract in active-state canon fields; keep it in the integration artifact surface.
- If the generated routing looks wrong, patch the integration script or the repo-owned source surface instead of inventing prompt glue ad hoc.
