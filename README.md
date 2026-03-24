# Memory V3 Bundle Source

Portable two-state memory bundle for Aira + worker LLM projects.

This repository is the canonical source for the installable `memory-v3-bundle`.

## What The Bundle Installs

- root `AGENTS.md` as a micro bootstrap
- `/.project-memory/` with minimal canon, playbooks, retrieval rules, docs index, and verification commands
- `/.automation/scripts/aira-memory` as the only human-facing operator CLI
- `/.automation/scripts/` for retrieval, closeout, extraction, promotion, audit, and hub rebuild
- `/.automation/memory-v3/` tracked source assets for global skills and Obsidian surfaces

## Build A Bundle Manually

```sh
./scripts/package-memory-v3.sh --bundle-name memory-v3-bundle-v3
```

The command writes:

- `output/<bundle-name>/`
- `output/<bundle-name>.tar.gz`

Notes:

- `--bundle-name` is explicit. The script does not derive it from `package.json`.
- Re-running the command with the same name replaces the archive at `output/<bundle-name>.tar.gz`.

## Install Into A Target Repository

```sh
./install-memory-v3.sh --target /absolute/path/to/project
```

With optional global sync:

```sh
./install-memory-v3.sh \
  --target /absolute/path/to/project \
  --sync-global-skills \
  --sync-obsidian
```

## After Install

The installer writes a factual greenfield baseline. Update only these project-specific surfaces when you know the real values:

- `AGENTS.md`
- `/.project-memory/canon/repo-landmines.md`
- `/.project-memory/canon/current-state.md`
- `/.project-memory/verify-commands.md`
- `/.project-memory/docs-index.md`

Then use:

```sh
./.automation/scripts/aira-memory bugfix --query "fix auth redirect loop"
./.automation/scripts/aira-memory feature --query "your task summary"
./.automation/scripts/aira-memory finish --task-id task-001
```

Then review `/.automation/workspace/memory-candidates/task-001/promotion-review.md` and rerun with `--apply`.

## Rules

- If knowledge can be discovered from code, config, scripts, or local docs, it does not belong in global context.
- Retrieval prefers project-local validated notes first and labels cross-project fallback explicitly when it is used.
- Active state lives only in `/.project-memory/canon/current-state.md` and `/.project-memory/verify-commands.md`.
