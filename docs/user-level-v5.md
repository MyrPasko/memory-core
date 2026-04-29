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
  - `/.claude`
- those mounted paths are added to `.git/info/exclude`

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
- reattach preserves curated project memory and verification commands instead of reseeding them
- if a repo already has tracked `AGENTS.md`, `/.project-memory`, `/.automation`, or `/.claude`, attach is a hard conflict and should fail before mounting anything
- detach removes the managed symlinks and also removes the managed git-exclude block when no other attached worktree still depends on it
- `memory-core-user list` reports only currently attached worktrees, not every historical state directory
- `memory-core-user prune` reports stale detached state directories; `--apply` removes them
