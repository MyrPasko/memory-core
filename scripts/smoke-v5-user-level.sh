#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE_NAME="memory-core.v5-smoke"
KEEP_TEMP="false"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/smoke-v5-user-level.sh [--bundle-name <name>] [--keep-temp]

Options:
  --bundle-name <name>   Bundle name used for the packaging smoke step
  --keep-temp            Preserve the disposable temp directory for inspection
  -h, --help             Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bundle-name)
      BUNDLE_NAME="${2:?missing value for --bundle-name}"
      shift 2
      ;;
    --keep-temp)
      KEEP_TEMP="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

TMP_DIR="$(mktemp -d /private/tmp/memory-core-v5-smoke.XXXXXX)"

cleanup() {
  if [[ "$KEEP_TEMP" == "true" ]]; then
    printf 'kept_temp_dir=%s\n' "$TMP_DIR"
    return
  fi
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if ! grep -Fq "$needle" <<<"$haystack"; then
    echo "Expected output to contain: $needle" >&2
    exit 1
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  if grep -Fq "$needle" <<<"$haystack"; then
    echo "Expected output to omit: $needle" >&2
    exit 1
  fi
}

step() {
  printf 'step=%s\n' "$1"
}

cd "$ROOT_DIR"

step package-bundle
PACKAGE_OUTPUT="$(bash ./scripts/package-memory-core.sh --bundle-name "$BUNDLE_NAME")"
assert_contains "$PACKAGE_OUTPUT" "output/$BUNDLE_NAME.tar.gz"

SRC_HOME="$TMP_DIR/home-src"
SRC_BIN="$TMP_DIR/bin-src"
BUNDLE_HOME="$TMP_DIR/home-bundle"
BUNDLE_BIN="$TMP_DIR/bin-bundle"

step install-source-home
bash ./install-memory-core-user.sh --home "$SRC_HOME" --bin-dir "$SRC_BIN" >/dev/null
SRC_LAUNCHER="$SRC_HOME/bin/memory-core-user"

step install-bundle-home
bash "./output/$BUNDLE_NAME/install-memory-core-user.sh" --home "$BUNDLE_HOME" --bin-dir "$BUNDLE_BIN" >/dev/null
BUNDLE_LAUNCHER="$BUNDLE_HOME/bin/memory-core-user"

step doctor-home-source
SOURCE_HOME_DOCTOR="$("$SRC_LAUNCHER" doctor)"
assert_contains "$SOURCE_HOME_DOCTOR" "overall=ok"

step doctor-home-bundle
BUNDLE_HOME_DOCTOR="$("$BUNDLE_LAUNCHER" doctor)"
assert_contains "$BUNDLE_HOME_DOCTOR" "overall=ok"

MAIN_REPO="$TMP_DIR/main-repo"
MAIN_WT="$TMP_DIR/main-repo-wt2"

step init-multi-worktree-repo
mkdir -p "$MAIN_REPO"
git -C "$MAIN_REPO" init -b main >/dev/null
printf 'hello\n' > "$MAIN_REPO/README.md"
git -C "$MAIN_REPO" add README.md
git -C "$MAIN_REPO" -c user.name=Aira -c user.email=aira@example.com commit -m init >/dev/null
git -C "$MAIN_REPO" worktree add "$MAIN_WT" -b feature >/dev/null

step attach-main-and-worktree
"$SRC_LAUNCHER" attach --repo "$MAIN_REPO" >/dev/null
"$SRC_LAUNCHER" attach --repo "$MAIN_WT" >/dev/null

step status-and-list
MAIN_STATUS="$("$SRC_LAUNCHER" status --repo "$MAIN_REPO")"
WT_STATUS="$("$SRC_LAUNCHER" status --repo "$MAIN_WT")"
LIST_OUTPUT="$("$SRC_LAUNCHER" list)"
assert_contains "$MAIN_STATUS" "attached_state_root="
assert_not_contains "$MAIN_STATUS" "attached_state_root=missing"
assert_contains "$WT_STATUS" "branch=feature"
assert_contains "$LIST_OUTPUT" "status=attached"

step doctor-attached-worktrees
MAIN_DOCTOR="$("$SRC_LAUNCHER" doctor --repo "$MAIN_REPO")"
WT_DOCTOR="$("$SRC_LAUNCHER" doctor --repo "$MAIN_WT")"
assert_contains "$MAIN_DOCTOR" "overall=ok"
assert_contains "$WT_DOCTOR" "overall=ok"

step branch-rename-stability
BEFORE_STATE_ROOT="$(sed -n 's/^state_root=//p' <<<"$WT_STATUS")"
git -C "$MAIN_REPO" branch -m feature feature-renamed
WT_STATUS_AFTER_RENAME="$("$SRC_LAUNCHER" status --repo "$MAIN_WT")"
AFTER_STATE_ROOT="$(sed -n 's/^state_root=//p' <<<"$WT_STATUS_AFTER_RENAME")"
assert_contains "$WT_STATUS_AFTER_RENAME" "branch=feature-renamed"
if [[ "$BEFORE_STATE_ROOT" != "$AFTER_STATE_ROOT" ]]; then
  echo "State root changed after branch rename" >&2
  exit 1
fi

step structured-closeout-smoke
(cd "$MAIN_REPO" && ./.automation/scripts/aira-memory feature --query "run disposable V5 closeout smoke" >/dev/null)
cat > "$MAIN_REPO/.automation/workspace/implement.result.md" <<'EOF'
# Implement Result

## Plan Summary
- Run disposable closeout smoke for the V5 user-level workflow.

## Exact References Used
- scripts/memory-core-user.sh
- scripts/smoke-v5-user-level.sh

## Actual Write-Scope Touched
- scripts/memory-core-user.sh
- scripts/smoke-v5-user-level.sh

## Forbidden Moves
- None during disposable smoke.

## Changes Made
- Validated the closeout path against a disposable attached worktree.

## Verification Commands And Outcomes
- `./.automation/scripts/aira-memory finish --task-id v5-smoke-001 --task-type feature` (pass)

## Review-Closeout Actions
- None.

## Open Findings
None
EOF
cat > "$MAIN_REPO/.automation/workspace/implement.result.json" <<'EOF'
{
  "task_id": "v5-smoke-001",
  "task_type": "feature",
  "branch": "main",
  "write_scope": [
    "scripts/memory-core-user.sh",
    "scripts/smoke-v5-user-level.sh"
  ],
  "forbidden_moves": [
    "Do not widen the smoke scope beyond disposable verification."
  ],
  "verification": [
    {
      "kind": "tests",
      "command": "./.automation/scripts/aira-memory finish --task-id v5-smoke-001 --task-type feature",
      "result": "pass",
      "notes": "Structured closeout sidecar smoke passed in an attached disposable worktree."
    }
  ],
  "open_findings": [],
  "review_closeout": []
}
EOF
CLOSEOUT_OUTPUT="$(cd "$MAIN_REPO" && ./.automation/scripts/aira-memory finish --task-id v5-smoke-001 --task-type feature)"
assert_contains "$CLOSEOUT_OUTPUT" "\"manifest\""
assert_not_contains "$CLOSEOUT_OUTPUT" "\"failed_stage\""
if [[ ! -f "$MAIN_REPO/.automation/workspace/memory-candidates/v5-smoke-001/promotion-review.md" ]]; then
  echo "Expected promotion-review.md to be generated during closeout smoke" >&2
  exit 1
fi

step reattach-preserves-state
printf 'custom-risk\n' >> "$MAIN_REPO/.project-memory/canon/current-state.md"
"$SRC_LAUNCHER" detach --repo "$MAIN_REPO" >/dev/null
"$SRC_LAUNCHER" attach --repo "$MAIN_REPO" >/dev/null
if ! grep -Fq 'custom-risk' "$MAIN_REPO/.project-memory/canon/current-state.md"; then
  echo "Reattach did not preserve curated state" >&2
  exit 1
fi

step exclude-cleanup-cycle
COMMON_EXCLUDE="$(git -C "$MAIN_REPO" rev-parse --path-format=absolute --git-common-dir)/info/exclude"
assert_contains "$(cat "$COMMON_EXCLUDE")" "# memory-core-v5 begin"
"$SRC_LAUNCHER" detach --repo "$MAIN_WT" >/dev/null
assert_contains "$(cat "$COMMON_EXCLUDE")" "# memory-core-v5 begin"
"$SRC_LAUNCHER" detach --repo "$MAIN_REPO" >/dev/null
assert_not_contains "$(cat "$COMMON_EXCLUDE")" "# memory-core-v5 begin"

step prune-stale-state
PRUNE_DRY_RUN="$("$SRC_LAUNCHER" prune)"
assert_contains "$PRUNE_DRY_RUN" "status=stale"
PRUNE_APPLY="$("$SRC_LAUNCHER" prune --apply)"
assert_contains "$PRUNE_APPLY" "mode=pruned"
POST_PRUNE="$("$SRC_LAUNCHER" prune)"
assert_contains "$POST_PRUNE" "No stale Memory Core V5 state directories to prune."

step conflict-refusal
CONFLICT_REPO="$TMP_DIR/conflict-repo"
mkdir -p "$CONFLICT_REPO"
git -C "$CONFLICT_REPO" init -b main >/dev/null
printf 'conflict\n' > "$CONFLICT_REPO/AGENTS.md"
git -C "$CONFLICT_REPO" add AGENTS.md
git -C "$CONFLICT_REPO" -c user.name=Aira -c user.email=aira@example.com commit -m init >/dev/null
if "$SRC_LAUNCHER" attach --repo "$CONFLICT_REPO" >/tmp/memory-core-v5-conflict.out 2>/tmp/memory-core-v5-conflict.err; then
  echo "Attach should have refused a tracked AGENTS.md conflict" >&2
  exit 1
fi
assert_contains "$(cat /tmp/memory-core-v5-conflict.err)" "tracked repo path already exists in git index: AGENTS.md"

step claude-merge-mode
MERGE_REPO="$TMP_DIR/merge-repo"
mkdir -p "$MERGE_REPO/.claude/agents" "$MERGE_REPO/.claude/skills"
git -C "$MERGE_REPO" init -b main >/dev/null
printf 'merge\n' > "$MERGE_REPO/README.md"
cat <<'EOF' > "$MERGE_REPO/.claude/agents/custom-agent.md"
---
name: custom-agent
description: Repo-owned billing specialist for domain implementation work.
---

# Custom Agent

## Role
Billing migration specialist

## Objective
Help with repository-specific billing domain tasks.
EOF
cat <<'EOF' > "$MERGE_REPO/.claude/agents/aira-domain-helper.md"
---
name: aira-domain-helper
description: Repo-owned Aira-prefixed helper for billing migration work.
---

# Aira Domain Helper

## Role
Billing migration specialist

## Objective
Assist with repository-specific billing migrations.
EOF
cat <<'EOF' > "$MERGE_REPO/.claude/agents/workflow-router.md"
---
name: workflow-router
description: Controller-like router for legacy workflow handoffs.
---

# Workflow Router

## Role
Controller for workflow handoffs

## Objective
Route implementation work across legacy workflow surfaces.
EOF
cat <<'EOF' > "$MERGE_REPO/.claude/skills/custom-skill.md"
---
name: custom-skill
description: Build and install helper for repository setup.
---

This skill automates build and install steps for repository setup.
EOF
git -C "$MERGE_REPO" add README.md .claude/agents/custom-agent.md .claude/agents/aira-domain-helper.md .claude/agents/workflow-router.md .claude/skills/custom-skill.md
git -C "$MERGE_REPO" -c user.name=Aira -c user.email=aira@example.com commit -m init >/dev/null
"$SRC_LAUNCHER" attach --repo "$MERGE_REPO" --claude-mode merge >/dev/null
MERGE_STATUS="$("$SRC_LAUNCHER" status --repo "$MERGE_REPO")"
MERGE_DOCTOR="$("$SRC_LAUNCHER" doctor --repo "$MERGE_REPO")"
assert_contains "$MERGE_STATUS" "claude_mode=merge"
assert_contains "$MERGE_DOCTOR" "overall=ok"
if [[ ! -f "$MERGE_REPO/.claude/agents/custom-agent.md" ]]; then
  echo "Merge mode should preserve existing custom Claude agents" >&2
  exit 1
fi
if [[ ! -f "$MERGE_REPO/.claude/skills/custom-skill.md" ]]; then
  echo "Merge mode should preserve existing custom Claude skills" >&2
  exit 1
fi
if [[ ! -L "$MERGE_REPO/.claude/agents/aira-controller.md" ]]; then
  echo "Merge mode should install managed Aira agent symlinks under .claude/agents" >&2
  exit 1
fi
INTEGRATION_OUTPUT="$(cd "$MERGE_REPO" && ./.automation/scripts/integrate-agent-surface)"
assert_contains "$INTEGRATION_OUTPUT" "\"routing_contract\""
if [[ ! -f "$MERGE_REPO/.project-memory/integrations/agent-routing/routing-contract.md" ]]; then
  echo "Integration script should generate a routing contract for repo-owned Claude surfaces" >&2
  exit 1
fi
if [[ ! -f "$MERGE_REPO/.project-memory/integrations/agent-routing/existing-skills.md" ]]; then
  echo "Integration script should generate a skill inventory for repo-owned Claude surfaces" >&2
  exit 1
fi
assert_contains "$(cat "$MERGE_REPO/.project-memory/integrations/agent-routing/existing-agents.md")" "custom-agent"
assert_contains "$(cat "$MERGE_REPO/.project-memory/integrations/agent-routing/existing-agents.md")" "aira-domain-helper"
assert_contains "$(cat "$MERGE_REPO/.project-memory/integrations/agent-routing/existing-skills.md")" "custom-skill"
assert_contains "$(cat "$MERGE_REPO/.project-memory/integrations/agent-routing/routing-contract.md")" '`aira-domain-helper`: `domain-specialist`.'
assert_contains "$(cat "$MERGE_REPO/.project-memory/integrations/agent-routing/routing-contract.md")" '`workflow-router`: `governance-collision-risk`.'
assert_contains "$(cat "$MERGE_REPO/.project-memory/integrations/agent-routing/routing-contract.md")" '`custom-skill`: `deterministic-tool-skill`.'
assert_contains "$(cat "$MERGE_REPO/.claude/agents/aira-controller.md")" 'run `./.automation/scripts/integrate-agent-surface` before planning or delegation'
"$SRC_LAUNCHER" detach --repo "$MERGE_REPO" >/dev/null
if [[ ! -f "$MERGE_REPO/.claude/agents/custom-agent.md" ]]; then
  echo "Detach should not remove repo-owned Claude agents" >&2
  exit 1
fi
if [[ -e "$MERGE_REPO/.claude/agents/aira-controller.md" ]]; then
  echo "Detach should remove only the managed Aira merge-mode entries" >&2
  exit 1
fi

step bundle-install-attach-smoke
BUNDLE_REPO="$TMP_DIR/bundle-repo"
mkdir -p "$BUNDLE_REPO"
git -C "$BUNDLE_REPO" init -b main >/dev/null
printf 'bundle\n' > "$BUNDLE_REPO/README.md"
git -C "$BUNDLE_REPO" add README.md
git -C "$BUNDLE_REPO" -c user.name=Aira -c user.email=aira@example.com commit -m init >/dev/null
"$BUNDLE_LAUNCHER" attach --repo "$BUNDLE_REPO" >/dev/null
BUNDLE_REPO_DOCTOR="$("$BUNDLE_LAUNCHER" doctor --repo "$BUNDLE_REPO")"
assert_contains "$BUNDLE_REPO_DOCTOR" "overall=ok"
"$BUNDLE_LAUNCHER" detach --repo "$BUNDLE_REPO" >/dev/null

step smoke-complete
printf 'result=ok\n'
printf 'temp_dir=%s\n' "$TMP_DIR"
