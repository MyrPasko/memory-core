---
project: memory-core
merged_baseline: memory-core-v5-claude-merge-hardened
next_slice: unassigned
active_risks: ["installer-and-workflow-must-stay-portable", "battle-tested-behavior-must-not-leak-project-specific-artifacts", "human-readable-closeout-must-stay-aligned-with-structured-sidecar", "v5-user-level-still-relies-on-existing-or-global-skill-surface-rather-than-user-installer-skill-sync"]
verification_reality: ["repo-level packaging changes must pass bash ./scripts/smoke-v5-user-level.sh", "user-level mode is verified across multiple worktrees of the same git common dir", "built-bundle install path is smoke-tested before release through the V5 smoke script", "structured-closeout-and-prune flows are covered by disposable-repo smoke", "repos with an existing repo-owned .claude directory are verified through attach --claude-mode merge"]
authoritative_since: 2026-04-29
---

# Current State

## Merged Baseline
- The repository is the canonical source for the installable Memory Core bundle, including repo-local V4 and user-level V5 modes, plus V5 doctor diagnostics, repeatable disposable smoke coverage, and merge-mode coexistence with repo-owned `.claude`.

## Next Slice
- No required slice is assigned. Remaining work is optional operator polish unless new release gates appear.

## Active Risks
- Packaging can drift away from the actual installed surface if source-only assets are not included in the bundle.
- Structured closeout now reduces parsing fragility, but markdown fallback paths still exist and must stay aligned with the machine contract.
- Battle-tested evidence and disposable artifacts must not leak into the install payload.
- User-level V5 can now merge into an existing repo-owned `.claude`, but it still relies on existing or global skill surfaces rather than explicit user-installer skill sync.

## Verification Reality
- `bash ./scripts/smoke-v5-user-level.sh` covers install from source repo, install from built bundle, doctor, branch rename stability, reattach state preservation, exclude cleanup, attach conflict behavior, merge-mode `.claude` coexistence, structured closeout sidecars, prune behavior, and user-level multi-worktree attachment.
