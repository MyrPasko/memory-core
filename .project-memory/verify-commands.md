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
- `bash ./scripts/smoke-v5-user-level.sh`

## Notes
- The V5 smoke script covers source install, built-bundle install, `memory-core-user doctor`, attach, detach, reattach preservation, branch rename stability, exclude cleanup, structured closeout sidecars, `prune`, and conflict refusal.
- Add only commands that are real, repeatable, and already supported by this repository.
- Until commands are curated here, do not imply green verification.
