# Memory Core V4 Bundle Source

Portable AI-assisted SDLC bundle with repo-local memory, human gates, and installable Claude user agents.

This repository is the canonical source for the installable `memory-core` bundle. The product is no longer just a memory helper. It is a controlled workflow package:

`context -> plan -> bounded execution -> review -> verification -> closeout`

## What The Bundle Installs

- root `AGENTS.md` as a minimal bootstrap
- `/.project-memory/` with canon, controller-worker contract, playbooks, retrieval rules, templates, docs index, and verification commands
- `/.automation/scripts/aira-memory` as the human-facing memory operator CLI
- `/.automation/scripts/` for retrieval, extraction, promotion, audit, hub rebuild, and closeout
- `/.claude/agents/` with Aira user agents for controller, planner, executor, reviewer, and memory roles
- optional adapter assets for Codex/OpenAI skills and Obsidian sync

## Product Position

The bundle is designed for controlled AI-assisted delivery, not autonomous code dumping.

Core rule:

- agents are useful because their authority is limited

That authority model is encoded in:

- `AGENTS.md`
- `/.project-memory/canon/controller-worker-contract.md`
- `/.project-memory/canon/workflow.md`

## Build A Bundle Manually

```sh
./scripts/package-memory-core.sh --bundle-name memory-core.0.4
```

The command writes:

- `output/<bundle-name>/`
- `output/<bundle-name>.tar.gz`

Notes:

- `--bundle-name` is explicit. The script does not derive it from `package.json`.
- Re-running with the same name replaces the previous archive.
- The built tarball is the supported distribution artifact. The source repo remains canonical source, not install payload.

Compatibility wrapper:

```sh
./scripts/package-memory-v3.sh --bundle-name memory-core.0.4
```

## Install Into A Target Repository

```sh
./install-memory-core.sh --target /absolute/path/to/project
```

Optional environment integrations:

```sh
./install-memory-core.sh \
  --target /absolute/path/to/project \
  --sync-global-skills \
  --sync-obsidian \
  --install-adapters
```

Default behavior:

- install footprint is repo-local only
- global skill sync is opt-in
- Obsidian sync is opt-in
- adapter installation is opt-in

Compatibility wrapper:

```sh
./install-memory-v3.sh --target /absolute/path/to/project
```

## Installed Repo Surface

- `AGENTS.md`
- `/.project-memory/canon/constraints.md`
- `/.project-memory/canon/controller-worker-contract.md`
- `/.project-memory/canon/current-state.md`
- `/.project-memory/canon/repo-landmines.md`
- `/.project-memory/canon/workflow.md`
- `/.project-memory/verify-commands.md`
- `/.project-memory/docs-index.md`
- `/.project-memory/templates/implement-result.md`
- `/.automation/scripts/aira-memory`
- `/.claude/agents/aira-*.md`

## After Install

The installer writes a factual greenfield baseline. Replace only the fields that depend on the target repo:

- `AGENTS.md` when you need project-specific bootstrap pointers
- `/.project-memory/canon/repo-landmines.md`
- `/.project-memory/canon/current-state.md`
- `/.project-memory/verify-commands.md`
- `/.project-memory/docs-index.md`

For medium or large tasks, use the installed controller agent plus the operator CLI:

```sh
./.automation/scripts/aira-memory feature --query "your task summary"
```

Then hand the generated bundle and the accepted plan to `/.claude/agents/aira-controller.md`.

For closeout:

```sh
./.automation/scripts/aira-memory finish --task-id task-001
```

Review:

- `/.automation/workspace/implement.result.md`
- `/.automation/workspace/memory-candidates/task-001/promotion-review.md`

Apply promotion only after explicit approval.

## Rules

- If knowledge can be recovered from code, config, scripts, or local docs, it does not belong in bootstrap memory.
- Repo canon is the only authority for active state and verification commands.
- Promotion is a separate act from extraction.
- Project-specific battle evidence is design input for this product, not part of the install payload.
