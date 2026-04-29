---
project: memory-core
merged_baseline: memory-core-v5-agent-routing-hardened
next_slice: unassigned
active_risks: ["portable-installer-and-workflow-must-stay-aligned", "battle-tested-evidence-must-not-leak-into-install-payload", "markdown-closeout-must-stay-aligned-with-structured-sidecar", "v5-user-level-still-relies-on-existing-or-global-skill-surface"]
verification_reality: ["v5-smoke-script-is-the-release-gate", "user-level-mode-is-smoke-tested-across-shared-git-common-dir-worktrees", "merge-mode-existing-dot-claude-coexistence-is-smoke-tested", "repo-owned-claude-surfaces-can-be-rewritten-into-routing-artifacts"]
authoritative_since: 2026-04-29
---

# Current State

## Merged Baseline
- The repository is the canonical source for repo-local V4 and user-level V5, including V5 doctor, disposable smoke coverage, merge-mode `.claude` coexistence, and deterministic routing artifacts for repo-owned Claude surfaces.

## Next Slice
- No required slice is assigned.

## Active Risks
- Packaging can drift away from the installed surface.
- Markdown closeout fallback must stay aligned with the structured sidecar.
- Disposable evidence must not leak into the install payload.
- User-level V5 still relies on existing or global skill surfaces rather than explicit installer sync.

## Verification Reality
- `bash ./scripts/smoke-v5-user-level.sh` covers source install, built-bundle install, doctor, branch rename stability, reattach preservation, exclude cleanup, conflict refusal, merge-mode `.claude` coexistence, routing artifact generation, structured closeout sidecars, prune behavior, and user-level multi-worktree attachment.
