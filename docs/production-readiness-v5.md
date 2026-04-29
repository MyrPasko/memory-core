# Memory Core V5 Production Readiness

## Ready Now

- User-level install works from both source repo and built bundle.
- Worktree identity is stable across branch rename and reattach.
- Attach refuses tracked or conflicting repo-owned memory surfaces before mounting.
- Detach removes managed symlinks and cleans the managed `info/exclude` block symmetrically.
- Reattach preserves curated per-worktree state instead of reseeding it.
- Multi-worktree attachment under one git common dir is supported and smoke-tested.

## Must Fix Before Production

- Closeout must not rely only on markdown phrasing for verification, write-scope, and findings.
- User-level registry needs explicit stale-state lifecycle management, not just attached-state discovery.
- Production verification needs repeatable smoke coverage for source install, bundle install, closeout, and multi-project user-level behavior.
- Product docs must clearly separate authoritative repo state, generated artifacts, and optional Obsidian integration behavior.

## Nice To Have Later

- Add `doctor`-style diagnostics for broken symlinks, half-detached repos, and missing core assets.
- Add migration helpers between repo-local V4 and user-level V5 modes.
- Normalize legacy `memory-v3` naming in internal paths and module names.
- Add a richer human-readable registry view for many attached projects and worktrees.
- Add stricter automated regression coverage around parser edge cases and promotion/audit workflows.

## Current Hardening Slice

- Introduce a structured closeout sidecar for `implement.result`.
- Teach `finish`, extraction, and audit to prefer structured closeout data when available.
- Add a `prune` command for stale detached user-level state.
