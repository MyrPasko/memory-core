---
project: memory-core
merged_baseline: memory-core-v4-source-repo
next_slice: implement-memory-core-v4
active_risks: ["installer-and-workflow-must-stay-portable", "battle-tested-behavior-must-not-leak-project-specific-artifacts"]
verification_reality: ["repo-level smoke tests are required for each packaging change"]
authoritative_since: 2026-04-27
---

# Current State

## Merged Baseline
- The repository is the canonical source for the installable Memory Core V4 bundle.

## Next Slice
- Complete the v4 installation surface and workflow behavior hardening.

## Active Risks
- Packaging can drift away from the actual installed surface if source-only assets are not included in the bundle.
- Retrieval and closeout can still look correct while losing verification fidelity unless extraction stays strict.

## Verification Reality
- Smoke tests must cover install from source repo, install from built bundle, context generation, closeout, and audit behavior.
