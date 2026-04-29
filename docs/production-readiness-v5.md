# Memory Core V5 Production Readiness

## Ready Now

- User-level install works from both source repo and built bundle.
- Worktree identity is stable across branch rename and reattach.
- Attach refuses tracked or conflicting repo-owned memory surfaces before mounting.
- Detach removes managed symlinks and cleans the managed `info/exclude` block symmetrically.
- Reattach preserves curated per-worktree state instead of reseeding it.
- Multi-worktree attachment under one git common dir is supported and smoke-tested.
- `memory-core-user doctor` diagnoses missing core assets, broken managed links, metadata drift, and half-detached repos.
- A disposable regression script now covers source install, bundle install, doctor, multi-worktree attach, branch rename stability, structured closeout, prune, and conflict refusal.

## Must Fix Before Production

- Keep running the disposable smoke flow before release packaging changes.
- Keep the human-readable closeout markdown aligned with the machine-readable sidecar while both formats still exist.

## Nice To Have Later

- Add migration helpers between repo-local V4 and user-level V5 modes.
- Normalize legacy `memory-v3` naming in internal paths and module names.
- Add a richer human-readable registry view for many attached projects and worktrees.
- Add stricter automated regression coverage around parser edge cases and promotion/audit workflows.

## Completed Hardening Slice

- Add `doctor`-style diagnostics for broken symlinks, half-detached repos, and missing core assets.
- Add a repeatable disposable regression harness for V5 source install, built-bundle install, multi-worktree attach, closeout, prune, and conflict behavior.
