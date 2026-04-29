---
project: memory-core
merged_baseline: memory-core-v5-source-repo
next_slice: harden-closeout-contract-and-user-level-project-registry
active_risks: ["installer-and-workflow-must-stay-portable", "battle-tested-behavior-must-not-leak-project-specific-artifacts", "closeout-contract-remains-markdown-fragile", "user-level-project-registry-still-needs-prune-strategy"]
verification_reality: ["repo-level smoke tests are required for each packaging change", "user-level mode must be verified across multiple worktrees of the same git common dir", "built-bundle-install-path-must-be-smoke-tested-before-release"]
authoritative_since: 2026-04-28
---

# Current State

## Merged Baseline
- The repository is the canonical source for the installable Memory Core bundle, including repo-local V4 and user-level V5 modes.

## Next Slice
- Harden the closeout contract and add a more explicit lifecycle strategy for user-level project registry state.

## Active Risks
- Packaging can drift away from the actual installed surface if source-only assets are not included in the bundle.
- Retrieval and closeout can still look correct while losing verification fidelity unless extraction stays strict.
- User-level project state is now preserved across reattach, but detached state accumulation still needs an explicit cleanup strategy.

## Verification Reality
- Smoke tests must cover install from source repo, install from built bundle, branch rename stability, reattach state preservation, exclude cleanup, attach conflict behavior, and user-level multi-worktree attachment.
