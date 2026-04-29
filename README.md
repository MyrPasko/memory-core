# Memory Core Bundle Source

Portable AI-assisted SDLC bundle with repo-local memory, human gates, installable Claude user agents, and a parallel user-level worktree mode.

This repository is the canonical source for two parallel installation models:

- `V4`: repo-local install for teams or repos that can carry the memory surface directly
- `V5`: user-level install for local multi-worktree use without pushing memory files into git

Both models keep the same controlled workflow:

`context -> plan -> bounded execution -> review -> verification -> closeout`

## Product Position

The bundle is designed for controlled AI-assisted delivery, not autonomous code dumping.

Core rule:

- agents are useful because their authority is limited

That authority model is encoded in:

- `AGENTS.md`
- `/.project-memory/canon/controller-worker-contract.md`
- `/.project-memory/canon/workflow.md`

## V4 Repo-Local Mode

### What It Installs

- root `AGENTS.md` as a minimal bootstrap
- `/.project-memory/` with canon, controller-worker contract, playbooks, retrieval rules, templates, docs index, and verification commands
- `/.automation/scripts/aira-memory` as the human-facing memory operator CLI
- `/.automation/scripts/` for retrieval, extraction, promotion, audit, hub rebuild, and closeout
- `/.claude/agents/` with Aira user agents for controller, planner, executor, reviewer, and memory roles
- optional adapter assets for Codex/OpenAI skills and Obsidian sync
- optional integration skill for rewriting repo-owned Claude surfaces into Aira routing artifacts

### Install

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

## V5 User-Level Worktree Mode

### What It Does

V5 installs the core once at user level and keeps mutable memory state outside git, per worktree.

Suggested layout after install:

- `~/.memory-core/core/` shared scripts, agents, templates, retrieval rules
- `~/.memory-core/projects/<repo-id>/worktrees/<worktree-id>/` externalized per-worktree state

Identity rules:

- `repo-id` comes from the git common dir, so one repository with many worktrees stays grouped under one project namespace
- the logical project name comes from the base repository, not from the individual worktree folder name
- reattaching an existing worktree preserves curated state instead of reseeding it

When you attach a repo or worktree, V5 always mounts these repo paths as symlinks:

- `AGENTS.md`
- `/.project-memory`
- `/.automation`

For `/.claude`, V5 has two modes:

- default `mount` mode mounts `/.claude` itself as a managed symlink
- `merge` mode keeps an existing repo-owned `/.claude` directory and only adds managed Aira agent symlinks under `/.claude/agents/`

It also adds those paths to `.git/info/exclude`, so they stay out of git.
On detach, the managed ignore block is removed again. If another attached worktree for the same repo still exists, the shared common-dir ignore block is preserved until the last attachment is detached.

### Install

```sh
./install-memory-core-user.sh
```

Optional install location overrides:

```sh
./install-memory-core-user.sh --home ~/.memory-core --bin-dir ~/.local/bin
```

### Attach To A Worktree

```sh
memory-core-user attach --repo /absolute/path/to/worktree
memory-core-user attach --repo /absolute/path/to/worktree --claude-mode merge
```

Then use the same repo-local workflow from inside that attached worktree:

```sh
./.automation/scripts/aira-memory feature --query "your task summary"
```

Useful management commands:

```sh
memory-core-user doctor
memory-core-user doctor --repo /absolute/path/to/worktree
memory-core-user status --repo /absolute/path/to/worktree
memory-core-user list
memory-core-user detach --repo /absolute/path/to/worktree
memory-core-user prune
memory-core-user prune --apply
```

`memory-core-user doctor` validates the user-level install itself.
`memory-core-user doctor --repo ...` diagnoses broken symlinks, missing metadata, missing core assets, and half-detached worktrees.
`memory-core-user list` reports only currently attached worktrees.
`memory-core-user prune` shows stale detached state directories; `--apply` removes them.

Use `--claude-mode merge` when the repository already owns a real `/.claude` directory with existing agents, rules, or skills that must stay in place.
In merge mode, Memory Core preserves repo-owned `/.claude` content and adds only managed Aira agent symlinks under `/.claude/agents/`.

If the repository already has meaningful repo-owned Claude agents or skills, generate the deterministic integration layer for Aira before using them together:

```sh
./.automation/scripts/integrate-agent-surface
```

That command rewrites the repo-owned agent and skill surface into compact text artifacts under `/.project-memory/integrations/agent-routing/`:

- `integration-brief.md`
- `routing-contract.md`
- `existing-agents.md`
- `existing-skills.md`
- `inventory.json`

The routing contract keeps Aira controller, reviewer, and memory roles as governance authorities while letting repo-owned skills act as deterministic helpers and repo-owned agents act as bounded domain helpers. When repo-owned Claude surfaces exist, treat this contract as required before planning or delegation through Aira.

Attach is intentionally conservative:

- it refuses repos that already track `AGENTS.md`, `/.project-memory`, or `/.automation`
- in default `mount` mode it also refuses repos that already own `/.claude`
- in `merge` mode it preserves an existing repo-owned `/.claude` directory, but refuses conflicting `aira-*.md` agent entries or foreign symlink-based `.claude` layouts
- it refuses conflicting existing non-managed paths or foreign symlinks
- it is meant for local repos or worktrees that do not already own this surface

### When To Use V5

Use V5 when:

- you work with many `git worktree` directories
- you want one user-level core install
- you do not want to push `AGENTS.md`, `/.project-memory`, `/.automation`, or `/.claude` into git
- you still want isolated active state per worktree
- you may need `--claude-mode merge` to coexist with an existing repo-owned `/.claude` directory

## Build A Bundle Manually

```sh
./scripts/package-memory-core.sh --bundle-name memory-core.0.5
./scripts/smoke-v5-user-level.sh
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
./scripts/package-memory-v3.sh --bundle-name memory-core.0.5
```

## After Install

For V4, the installer writes a factual greenfield baseline inside the repo. Replace only the fields that depend on the target repo:

- `AGENTS.md`
- `/.project-memory/canon/repo-landmines.md`
- `/.project-memory/canon/current-state.md`
- `/.project-memory/verify-commands.md`
- `/.project-memory/docs-index.md`

For V5, those same files exist in the externalized worktree state and are mounted into the repo through symlinks.

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
- `/.automation/workspace/implement.result.json`
- `/.automation/workspace/memory-candidates/task-001/promotion-review.md`

Apply promotion only after explicit approval.

For production-grade closeout, treat `implement.result.json` as the machine-readable contract for verification, write-scope, forbidden moves, and open findings. The markdown file remains the human-readable companion.

## Rules

- If knowledge can be recovered from code, config, scripts, or local docs, it does not belong in bootstrap memory.
- Repo canon is the only authority for active state and verification commands.
- Promotion is a separate act from extraction.
- Project-specific battle evidence is design input for this product, not part of the install payload.
