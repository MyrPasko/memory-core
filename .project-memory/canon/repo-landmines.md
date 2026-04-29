---
kind: repo-landmines
project: memory-core
authoritative_since: 2026-04-27
---

# Repo Landmines

## Critical Landmines
- This repo packages a portable install bundle. Do not let project-specific trial artifacts leak into the install payload.
- Repo project memory is authoritative over Obsidian and generated summaries when they disagree.
- Worker output becomes durable knowledge only after extraction plus explicit promotion.
- `output/` is disposable build output and must not become source of truth.

## Do Not Infer From Code Alone
- Existing `memory-v3` names inside some adapter assets do not define the product name. The product surface is `memory-core v4`.
- Battle-tested strategy notes are design input. They are not install-time repo payload.
- If an example is domain-specific, move it into an explicit example surface or omit it from installation.
