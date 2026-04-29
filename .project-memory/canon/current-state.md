---
project: memory-core
merged_baseline: memory-core-v5-source-repo
next_slice: add-doctor-and-regression-harness-for-v5
active_risks: ["installer-and-workflow-must-stay-portable", "battle-tested-behavior-must-not-leak-project-specific-artifacts", "closeout-contract-now-prefers-structured-sidecar-but-markdown-fallback-still-exists", "user-level-prune-exists-but-doctor-and-regression-harness-are-still-missing"]
verification_reality: ["repo-level smoke tests are required for each packaging change", "user-level mode must be verified across multiple worktrees of the same git common dir", "built-bundle-install-path-must-be-smoke-tested-before-release", "structured-closeout-and-prune-flows-must-have disposable-repo smoke coverage"]
authoritative_since: 2026-04-28
---

# Current State

## Merged Baseline
- The repository is the canonical source for the installable Memory Core bundle, including repo-local V4 and user-level V5 modes.

## Next Slice
- Add `doctor`-style diagnostics and a more repeatable regression harness for V5.

## Active Risks
- Packaging can drift away from the actual installed surface if source-only assets are not included in the bundle.
- Structured closeout now reduces parsing fragility, but markdown fallback paths still exist and must stay aligned with the machine contract.
- User-level project state now has a prune path, but operator diagnostics for broken attachments are still thin.

## Verification Reality
- Smoke tests must cover install from source repo, install from built bundle, branch rename stability, reattach state preservation, exclude cleanup, attach conflict behavior, structured closeout sidecars, prune behavior, and user-level multi-worktree attachment.
