# Memory Core V5 User-Level Mode

## Goal

Allow one user-level Memory Core install to serve many local git worktrees without pushing the memory surface into git.

## Model

- shared core lives under `~/.memory-core/core/`
- per-worktree mutable state lives under `~/.memory-core/projects/<repo-id>/worktrees/<worktree-id>/`
- `repo-id` is derived from the git common dir, so one project with many worktrees stays under one project namespace
- `project` identity is derived from the base repo, not from the worktree folder name
- repo-local paths are mounted as symlinks:
  - `AGENTS.md`
  - `/.project-memory`
  - `/.automation`
  - `/.claude` in default `mount` mode
- those mounted paths are added to `.git/info/exclude`
- when a repo already owns `/.claude`, `attach --claude-mode merge` preserves that directory and adds only managed Aira agent symlinks under `/.claude/agents/`

## Why This Exists

V4 assumes the repo can own and potentially commit the memory surface.

V5 exists for a different workflow:

- many `git worktree` directories
- one human operator
- one local machine
- no desire to push memory infrastructure into the remote repository

## Operational Notes

- each worktree gets isolated active state and workspace artifacts
- shared scripts, agents, templates, and retrieval rules are installed once
- the same `./.automation/scripts/aira-memory` workflow still works after attach
- `memory-core-user doctor` validates the user-level install and `doctor --repo <path>` checks for broken symlinks, missing metadata, missing core assets, and half-detached worktrees
- when a repo already has meaningful repo-owned Claude agents or skills, `./.automation/scripts/integrate-agent-surface` rewrites them into textual routing artifacts for Aira under `/.project-memory/integrations/agent-routing/`; treat that generated contract as required before Aira planning or delegation
- reattach preserves curated project memory and verification commands instead of reseeding them
- if a repo already has tracked `AGENTS.md`, `/.project-memory`, or `/.automation`, attach is a hard conflict and should fail before mounting anything
- if a repo already owns `/.claude`, default attach is a hard conflict; use `--claude-mode merge` to preserve repo-owned `.claude` content and add only managed Aira agent symlinks under `/.claude/agents/`
- detach removes the managed symlinks and also removes the managed git-exclude block when no other attached worktree still depends on it
- `memory-core-user list` reports only currently attached worktrees, not every historical state directory
- `memory-core-user prune` reports stale detached state directories; `--apply` removes them
