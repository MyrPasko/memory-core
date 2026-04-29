---
kind: verification-commands
version: 5
---

# Verification Commands

## Frontend
- No frontend verification commands are registered for this source repository.

## Backend
- No backend verification commands are registered for this source repository.

## Packaging
- `bash ./scripts/package-memory-core.sh --bundle-name memory-core.smoke`
- `bash ./install-memory-core-user.sh --home /tmp/memory-core-user-smoke --bin-dir /tmp/memory-core-user-bin`

## Notes
- Production hardening also needs disposable-repo smoke coverage for `implement.result.json` closeout and `memory-core-user prune`.
- Full V5 verification also requires disposable git repos with multiple worktrees to validate attach, detach, reattach preservation, branch rename stability, and conflict refusal.
- Add only commands that are real, repeatable, and already supported by this repository.
- Until commands are curated here, do not imply green verification.
