#!/usr/bin/env bash

set -euo pipefail

resolve_script_path() {
  local source="${BASH_SOURCE[0]}"
  while [[ -L "$source" ]]; do
    local dir
    dir="$(cd "$(dirname "$source")" && pwd)"
    source="$(readlink "$source")"
    [[ "$source" != /* ]] && source="$dir/$source"
  done
  printf '%s\n' "$source"
}

SCRIPT_PATH="$(resolve_script_path)"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
MEMORY_CORE_HOME="${MEMORY_CORE_HOME:-$(cd "$SCRIPT_DIR/.." && pwd)}"
CORE_ROOT="$MEMORY_CORE_HOME/core"
PROJECTS_ROOT="$MEMORY_CORE_HOME/projects"

usage() {
  cat <<'EOF'
Usage:
  memory-core-user <command> [args...]

Commands:
  attach    Attach Memory Core V5 to a git repo or worktree without committing memory files
  detach    Remove managed symlinks from a git repo or worktree
  status    Show the managed state for a repo or worktree
  doctor    Diagnose Memory Core V5 install or repo attachment problems
  list      List known attached repos and worktrees
  prune     Remove stale detached state directories from the user-level registry
  help      Show this help

Examples:
  memory-core-user doctor
  memory-core-user doctor --repo /absolute/path/to/worktree
  memory-core-user attach --repo /absolute/path/to/worktree
  memory-core-user status --repo /absolute/path/to/worktree
  memory-core-user detach --repo /absolute/path/to/worktree
EOF
}

require_core() {
  if [[ ! -d "$CORE_ROOT/.project-memory" || ! -d "$CORE_ROOT/.automation" || ! -d "$CORE_ROOT/.claude" ]]; then
    echo "Memory Core home is incomplete: $CORE_ROOT" >&2
    echo "Run install-memory-core-user.sh first." >&2
    exit 1
  fi
}

slugify() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

hash12() {
  printf '%s' "$1" | shasum -a 256 | awk '{print substr($1,1,12)}'
}

git_top() {
  git -C "$1" rev-parse --path-format=absolute --show-toplevel
}

git_common_dir() {
  git -C "$1" rev-parse --path-format=absolute --git-common-dir
}

git_dir_path() {
  git -C "$1" rev-parse --path-format=absolute --git-dir
}

git_branch_name() {
  git -C "$1" rev-parse --abbrev-ref HEAD
}

git_is_tracked() {
  git -C "$1" ls-files -- "$2" | grep -q .
}

project_name_for() {
  local repo_root="$1"
  local common_dir
  local base
  common_dir="$(git_common_dir "$repo_root")"
  base="$(basename "$common_dir")"
  if [[ "$base" == ".git" ]]; then
    base="$(basename "$(dirname "$common_dir")")"
  fi
  if [[ -z "$base" ]]; then
    base="$(basename "$repo_root")"
  fi
  printf '%s\n' "$base"
}

repo_id_for() {
  hash12 "$(git_common_dir "$1")"
}

worktree_id_for() {
  local repo_root="$1"
  local worktree_slug
  worktree_slug="$(slugify "$(basename "$repo_root")")"
  if [[ -z "$worktree_slug" ]]; then
    worktree_slug="worktree"
  fi
  printf '%s-%s\n' "$worktree_slug" "$(hash12 "$(git_dir_path "$repo_root")")"
}

state_root_for() {
  local repo_root="$1"
  local repo_id
  local worktree_id
  repo_id="$(repo_id_for "$repo_root")"
  worktree_id="$(worktree_id_for "$repo_root")"
  printf '%s\n' "$PROJECTS_ROOT/$repo_id/worktrees/$worktree_id"
}

ensure_parent() {
  mkdir -p "$(dirname "$1")"
}

ensure_symlink() {
  local target="$1"
  local link_path="$2"
  if [[ -L "$link_path" ]]; then
    local current
    current="$(readlink "$link_path")"
    if [[ "$current" == "$target" ]]; then
      return 0
    fi
    rm "$link_path"
  elif [[ -e "$link_path" ]]; then
    echo "Refusing to overwrite non-symlink path: $link_path" >&2
    exit 1
  fi
  ln -s "$target" "$link_path"
}

is_managed_target() {
  local target="$1"
  local repo_id="$2"
  [[ "$target" == "$PROJECTS_ROOT/$repo_id/"* ]]
}

managed_state_root_from_repo() {
  local repo_root="$1"
  local repo_id
  local target
  repo_id="$(repo_id_for "$repo_root")"
  if [[ -L "$repo_root/.project-memory" ]]; then
    target="$(readlink "$repo_root/.project-memory")"
    if is_managed_target "$target" "$repo_id"; then
      printf '%s\n' "$(dirname "$target")"
      return 0
    fi
  fi
  return 1
}

seed_file_if_missing() {
  local path="$1"
  local temp_file
  if [[ -e "$path" ]]; then
    return 0
  fi
  ensure_parent "$path"
  temp_file="$(mktemp)"
  cat >"$temp_file"
  mv "$temp_file" "$path"
}

exclude_patterns() {
  cat <<'EOF'
/AGENTS.md
/.project-memory
/.automation
/.claude
EOF
}

metadata_path_for() {
  local state_root="$1"
  printf '%s\n' "$state_root/metadata.json"
}

metadata_value() {
  local metadata="$1"
  local key="$2"
  sed -n "s/.*\"$key\": \"\\(.*\\)\".*/\\1/p" "$metadata" | head -n 1
}

metadata_is_attached() {
  local metadata="$1"
  local repo_root
  local expected_state_root
  local actual_state_root
  repo_root="$(metadata_value "$metadata" "repo_root")"
  expected_state_root="$(dirname "$metadata")"
  if [[ -z "$repo_root" || ! -d "$repo_root" ]]; then
    return 1
  fi
  actual_state_root="$(managed_state_root_from_repo "$repo_root" || true)"
  [[ -n "$actual_state_root" && "$actual_state_root" == "$expected_state_root" ]]
}

metadata_exists_for_repo() {
  local repo_root="$1"
  [[ -f "$(state_root_for "$repo_root")/metadata.json" ]]
}

cleanup_empty_registry_dirs() {
  local state_root="$1"
  local worktrees_dir
  local repo_dir
  worktrees_dir="$(dirname "$state_root")"
  repo_dir="$(dirname "$worktrees_dir")"
  rmdir "$worktrees_dir" 2>/dev/null || true
  rmdir "$repo_dir" 2>/dev/null || true
}

ensure_exclude_block() {
  local exclude_file="$1"
  local begin_marker="# memory-core-v5 begin"
  local end_marker="# memory-core-v5 end"
  ensure_parent "$exclude_file"
  touch "$exclude_file"
  if grep -Fqx "$begin_marker" "$exclude_file"; then
    return 0
  fi
  {
    printf '%s\n' "$begin_marker"
    exclude_patterns
    printf '%s\n' "$end_marker"
  } >>"$exclude_file"
}

remove_exclude_block() {
  local exclude_file="$1"
  local begin_marker="# memory-core-v5 begin"
  local end_marker="# memory-core-v5 end"
  local temp_file
  if [[ ! -f "$exclude_file" ]]; then
    return 0
  fi
  temp_file="$(mktemp)"
  awk -v begin="$begin_marker" -v end="$end_marker" '
    $0 == begin { skip=1; next }
    $0 == end { skip=0; next }
    skip != 1 { print }
  ' "$exclude_file" >"$temp_file"
  mv "$temp_file" "$exclude_file"
}

ensure_git_exclude() {
  local repo_root="$1"
  local exclude_targets=(
    "$(git_dir_path "$repo_root")/info/exclude"
    "$(git_common_dir "$repo_root")/info/exclude"
  )
  for exclude_file in "${exclude_targets[@]}"; do
    ensure_exclude_block "$exclude_file"
  done
}

repo_has_other_attached_worktrees() {
  local repo_root="$1"
  local repo_id
  local current_state_root
  repo_id="$(repo_id_for "$repo_root")"
  current_state_root="$(managed_state_root_from_repo "$repo_root" || true)"
  while IFS= read -r metadata; do
    local candidate_root
    local candidate_attached_root
    candidate_root="$(sed -n 's/.*"repo_root": "\(.*\)".*/\1/p' "$metadata" | head -n 1)"
    if [[ -z "$candidate_root" || "$candidate_root" == "$repo_root" ]]; then
      continue
    fi
    if [[ ! -d "$candidate_root" ]]; then
      continue
    fi
    candidate_attached_root="$(managed_state_root_from_repo "$candidate_root" || true)"
    if [[ -n "$candidate_attached_root" && "$candidate_attached_root" == "$PROJECTS_ROOT/$repo_id/"* ]]; then
      return 0
    fi
  done < <(find "$PROJECTS_ROOT/$repo_id/worktrees" -path '*/metadata.json' -type f 2>/dev/null | sort)
  return 1
}

remove_git_exclude() {
  local repo_root="$1"
  local worktree_exclude
  local common_exclude
  worktree_exclude="$(git_dir_path "$repo_root")/info/exclude"
  common_exclude="$(git_common_dir "$repo_root")/info/exclude"
  remove_exclude_block "$worktree_exclude"
  if ! repo_has_other_attached_worktrees "$repo_root"; then
    remove_exclude_block "$common_exclude"
  fi
}

has_exclude_block() {
  local exclude_file="$1"
  local begin_marker="# memory-core-v5 begin"
  [[ -f "$exclude_file" ]] && grep -Fqx "$begin_marker" "$exclude_file"
}

DOCTOR_ISSUES=()

doctor_reset() {
  DOCTOR_ISSUES=()
}

doctor_add_issue() {
  DOCTOR_ISSUES+=("$1")
}

doctor_print() {
  local issue_count="${#DOCTOR_ISSUES[@]}"
  printf 'issue_count=%s\n' "$issue_count"
  if [[ "$issue_count" -eq 0 ]]; then
    printf 'overall=ok\n'
    return 0
  fi
  printf 'overall=issues-found\n'
  local issue
  for issue in "${DOCTOR_ISSUES[@]}"; do
    printf 'issue=%s\n' "$issue"
  done
  return 1
}

doctor_repo_surface() {
  local repo_root="$1"
  local repo_id
  local candidate_state_root
  local attached_state_root
  local git_dir
  local common_dir
  local worktree_exclude
  local common_exclude
  local state_root
  local managed_link_count=0
  local rel_path
  local link_path
  local link_target
  local status

  doctor_reset

  repo_id="$(repo_id_for "$repo_root")"
  candidate_state_root="$(state_root_for "$repo_root")"
  attached_state_root="$(managed_state_root_from_repo "$repo_root" || true)"
  git_dir="$(git_dir_path "$repo_root")"
  common_dir="$(git_common_dir "$repo_root")"
  worktree_exclude="$git_dir/info/exclude"
  common_exclude="$common_dir/info/exclude"
  state_root="$candidate_state_root"
  if [[ -n "$attached_state_root" ]]; then
    state_root="$attached_state_root"
  fi

  printf 'doctor_scope=repo\n'
  printf 'repo_root=%s\n' "$repo_root"
  printf 'repo_id=%s\n' "$repo_id"
  printf 'worktree_id=%s\n' "$(worktree_id_for "$repo_root")"
  printf 'branch=%s\n' "$(git_branch_name "$repo_root")"
  printf 'core_root=%s\n' "$CORE_ROOT"
  printf 'candidate_state_root=%s\n' "$candidate_state_root"
  printf 'attached_state_root=%s\n' "$(if [[ -n "$attached_state_root" ]]; then printf '%s' "$attached_state_root"; else printf 'missing'; fi)"
  printf 'metadata_path=%s\n' "$(metadata_path_for "$state_root")"
  printf 'worktree_exclude=%s\n' "$worktree_exclude"
  printf 'common_exclude=%s\n' "$common_exclude"

  if [[ ! -d "$CORE_ROOT/.project-memory" ]]; then
    doctor_add_issue "missing core asset: $CORE_ROOT/.project-memory"
  fi
  if [[ ! -d "$CORE_ROOT/.automation" ]]; then
    doctor_add_issue "missing core asset: $CORE_ROOT/.automation"
  fi
  if [[ ! -d "$CORE_ROOT/.claude" ]]; then
    doctor_add_issue "missing core asset: $CORE_ROOT/.claude"
  fi
  if [[ ! -f "$CORE_ROOT/.claude/agents/aira-controller.md" ]]; then
    doctor_add_issue "missing controller agent: $CORE_ROOT/.claude/agents/aira-controller.md"
  fi
  if [[ ! -f "$CORE_ROOT/.automation/scripts/aira-memory" ]]; then
    doctor_add_issue "missing operator CLI: $CORE_ROOT/.automation/scripts/aira-memory"
  fi

  for rel_path in "AGENTS.md" ".project-memory" ".automation" ".claude"; do
    link_path="$repo_root/$rel_path"
    status="missing"
    if [[ -L "$link_path" ]]; then
      link_target="$(readlink "$link_path")"
      if is_managed_target "$link_target" "$repo_id"; then
        managed_link_count=$((managed_link_count + 1))
        if [[ -e "$link_target" ]]; then
          status="managed"
        else
          status="managed-broken"
          doctor_add_issue "broken managed symlink: $rel_path -> $link_target"
        fi
      else
        status="foreign-symlink"
        doctor_add_issue "foreign symlink blocks V5 attachment: $rel_path -> $link_target"
      fi
    elif [[ -e "$link_path" ]]; then
      status="repo-owned"
      doctor_add_issue "repo-owned path blocks V5 attachment: $rel_path"
    fi
    printf '%s=%s\n' "${rel_path//\//_}_status" "$status"
  done

  if [[ "$managed_link_count" -gt 0 && "$managed_link_count" -lt 4 ]]; then
    doctor_add_issue "partial managed attachment surface: found $managed_link_count of 4 required managed links"
  fi

  if [[ -n "$attached_state_root" ]]; then
    if [[ ! -f "$attached_state_root/metadata.json" ]]; then
      doctor_add_issue "attached worktree is missing metadata: $attached_state_root/metadata.json"
    else
      if [[ "$(metadata_value "$attached_state_root/metadata.json" "repo_root")" != "$repo_root" ]]; then
        doctor_add_issue "metadata repo_root mismatch for $attached_state_root/metadata.json"
      fi
      if [[ "$(metadata_value "$attached_state_root/metadata.json" "repo_id")" != "$repo_id" ]]; then
        doctor_add_issue "metadata repo_id mismatch for $attached_state_root/metadata.json"
      fi
      if [[ "$(metadata_value "$attached_state_root/metadata.json" "worktree_id")" != "$(worktree_id_for "$repo_root")" ]]; then
        doctor_add_issue "metadata worktree_id mismatch for $attached_state_root/metadata.json"
      fi
      if [[ "$(metadata_value "$attached_state_root/metadata.json" "common_git_dir")" != "$common_dir" ]]; then
        doctor_add_issue "metadata common_git_dir mismatch for $attached_state_root/metadata.json"
      fi
      if [[ "$(metadata_value "$attached_state_root/metadata.json" "git_dir")" != "$git_dir" ]]; then
        doctor_add_issue "metadata git_dir mismatch for $attached_state_root/metadata.json"
      fi
    fi

    if [[ ! -f "$attached_state_root/AGENTS.md" ]]; then
      doctor_add_issue "attached state is missing bootstrap file: $attached_state_root/AGENTS.md"
    fi
    if [[ ! -d "$attached_state_root/.project-memory" ]]; then
      doctor_add_issue "attached state is missing project memory: $attached_state_root/.project-memory"
    fi
    if [[ ! -d "$attached_state_root/.automation" ]]; then
      doctor_add_issue "attached state is missing automation surface: $attached_state_root/.automation"
    fi
    if [[ ! -d "$attached_state_root/.claude" ]]; then
      doctor_add_issue "attached state is missing agents surface: $attached_state_root/.claude"
    fi
    if ! has_exclude_block "$worktree_exclude"; then
      doctor_add_issue "attached worktree is missing the managed exclude block: $worktree_exclude"
    fi
    if ! has_exclude_block "$common_exclude"; then
      doctor_add_issue "attached repo is missing the shared exclude block: $common_exclude"
    fi
  else
    if has_exclude_block "$worktree_exclude"; then
      doctor_add_issue "detached worktree still has a managed exclude block: $worktree_exclude"
    fi
    if [[ "$managed_link_count" -gt 0 ]]; then
      doctor_add_issue "managed links exist but no attached state root could be resolved"
    fi
  fi

  if [[ -z "$attached_state_root" ]]; then
    if metadata_exists_for_repo "$repo_root"; then
      printf 'detached_state_root=%s\n' "$candidate_state_root"
    fi
  fi

  doctor_print
}

doctor_home_surface() {
  local attached_count=0
  local stale_count=0
  local metadata

  doctor_reset

  printf 'doctor_scope=home\n'
  printf 'memory_core_home=%s\n' "$MEMORY_CORE_HOME"
  printf 'core_root=%s\n' "$CORE_ROOT"
  printf 'projects_root=%s\n' "$PROJECTS_ROOT"

  if [[ ! -d "$CORE_ROOT" ]]; then
    doctor_add_issue "missing core root: $CORE_ROOT"
  fi
  if [[ ! -d "$CORE_ROOT/.project-memory" ]]; then
    doctor_add_issue "missing core asset: $CORE_ROOT/.project-memory"
  fi
  if [[ ! -d "$CORE_ROOT/.automation" ]]; then
    doctor_add_issue "missing core asset: $CORE_ROOT/.automation"
  fi
  if [[ ! -d "$CORE_ROOT/.claude" ]]; then
    doctor_add_issue "missing core asset: $CORE_ROOT/.claude"
  fi
  if [[ ! -f "$CORE_ROOT/.claude/agents/aira-controller.md" ]]; then
    doctor_add_issue "missing controller agent: $CORE_ROOT/.claude/agents/aira-controller.md"
  fi
  if [[ ! -f "$CORE_ROOT/.automation/scripts/aira-memory" ]]; then
    doctor_add_issue "missing operator CLI: $CORE_ROOT/.automation/scripts/aira-memory"
  fi

  mkdir -p "$PROJECTS_ROOT"
  while IFS= read -r metadata; do
    if metadata_is_attached "$metadata"; then
      attached_count=$((attached_count + 1))
    else
      stale_count=$((stale_count + 1))
    fi
  done < <(find "$PROJECTS_ROOT" -path '*/worktrees/*/metadata.json' -type f 2>/dev/null | sort)

  printf 'attached_worktrees=%s\n' "$attached_count"
  printf 'stale_state_dirs=%s\n' "$stale_count"

  doctor_print
}

preflight_attach() {
  local repo_root="$1"
  local desired_state_root="$2"
  local repo_id
  repo_id="$(repo_id_for "$repo_root")"

  for rel_path in "AGENTS.md" ".project-memory" ".automation" ".claude"; do
    local abs_path="$repo_root/$rel_path"
    if git_is_tracked "$repo_root" "$rel_path"; then
      echo "Attach is unsafe: tracked repo path already exists in git index: $rel_path" >&2
      exit 1
    fi
    if [[ -L "$abs_path" ]]; then
      local current_target
      current_target="$(readlink "$abs_path")"
      if ! is_managed_target "$current_target" "$repo_id"; then
        echo "Attach is unsafe: $rel_path is a symlink not managed by Memory Core V5: $current_target" >&2
        exit 1
      fi
      continue
    fi
    if [[ -e "$abs_path" ]]; then
      echo "Attach is unsafe: repo already owns path $rel_path. Remove or migrate it before using V5 attach." >&2
      exit 1
    fi
  done
}

render_state_files() {
  local repo_root="$1"
  local state_root="$2"
  local project_name
  local today
  project_name="$(project_name_for "$repo_root")"
  today="$(date +%F)"

  mkdir -p "$state_root/.project-memory/canon" "$state_root/.automation/workspace" "$state_root/.claude"

  seed_file_if_missing "$state_root/AGENTS.md" <<EOF
# Aira Bootstrap

Use this file as a bootstrap only. Do not treat it as the project manual.

## Load Next
- \`/.project-memory/canon/constraints.md\`
- \`/.project-memory/canon/controller-worker-contract.md\`
- \`/.project-memory/canon/workflow.md\`
- \`/.project-memory/canon/current-state.md\`
- \`/.project-memory/canon/repo-landmines.md\`
- \`/.project-memory/verify-commands.md\` for exact verification commands
- \`/.project-memory/docs-index.md\` for version-matched docs pointers

## Critical Landmines
- This repo uses externalized Memory Core V5 state through managed symlinks.
- Repo project memory is authoritative over Obsidian and generated summaries when they disagree.
- Agents are useful because their authority is limited.
- Do not promote memory artifacts automatically after extraction.

## Rule
- If knowledge is discoverable from code, config, scripts, or local docs, it does not belong in this bootstrap file.
EOF

  seed_file_if_missing "$state_root/.project-memory/canon/repo-landmines.md" <<EOF
---
kind: repo-landmines
project: $project_name
authoritative_since: $today
---

# Repo Landmines

## Critical Landmines
- This repository is attached to a user-level Memory Core V5 home. The managed memory surface is externalized and mounted through symlinks.
- Repo project memory is authoritative over Obsidian and generated summaries when they disagree.
- Worker output becomes durable knowledge only after extraction plus explicit promotion.
- Do not widen an accepted slice without controller approval and updated write-scope.

## Do Not Infer From Code Alone
- Verification success must come from real commands and real runs, not from installation defaults.
- Add only the hidden invariants, risky zones, or deprecated paths that repeatedly cause errors.
- If the repo already has tracked automation or agent infrastructure, do not blindly merge this externalized mode into it.
EOF

  seed_file_if_missing "$state_root/.project-memory/canon/current-state.md" <<EOF
---
project: $project_name
merged_baseline: repository-attached-to-memory-core-v5
next_slice: unassigned
active_risks: ["project-memory-not-yet-specialized"]
verification_reality: ["no-verification-commands-curated-yet"]
authoritative_since: $today
---

# Current State

## Merged Baseline
- The repository is attached to a user-level Memory Core V5 home, but no project-specific baseline has been recorded yet.

## Next Slice
- No slice is assigned yet.

## Active Risks
- Greenfield defaults are still in place. Replace them with real risks as soon as the first task is defined.

## Verification Reality
- No exact verification commands are curated yet. Do not imply successful verification until \`/.project-memory/verify-commands.md\` is filled with real commands.
EOF

  seed_file_if_missing "$state_root/.project-memory/canon/constraints.md" <<EOF
---
project: $project_name
kind: constraints
---

# Constraints

## Process
- Keep PRs narrow and reviewable.
- Never claim verification that did not happen.
- Treat review findings as hard gates.
- Keep controller-owned decisions out of worker execution unless explicitly included in the accepted plan.
- Agents are useful because their authority is limited.

## Memory Core
- Active project memory is externalized per worktree and mounted into the repo through symlinks.
- \`/.project-memory/canon/current-state.md\` is the only editable active-state store.
- \`/.project-memory/verify-commands.md\` is the only editable verification-command surface.
- Distilled knowledge belongs in note artifacts with explicit lifecycle status.
- Promotion is a separate act from extraction.
- Failures are first-class knowledge, not leftovers hidden inside session prose.

## Ownership
- Root bootstrap stays minimal and points into \`/.project-memory/\`; it is not a repo manual.
- Repo canon wins over Obsidian and generated project hubs when they disagree.
- Project hubs are generated summaries, not active-state documents.
- Worker output never becomes durable memory without an explicit promotion step.
EOF

  seed_file_if_missing "$state_root/.project-memory/canon/workflow.md" <<EOF
---
project: $project_name
kind: workflow
---

# Workflow

## Controlled AI-SDLC Loop
1. Attach the worktree through \`memory-core-user attach --repo <path>\`.
2. Use \`./.automation/scripts/aira-memory bugfix|feature|infra|investigation|review-closeout\` before medium or large tasks.
3. Use \`/.claude/agents/aira-controller.md\` as the canonical entrypoint for controller-led slices.
4. Keep active-project truth only in \`/.project-memory/canon/current-state.md\` and \`/.project-memory/verify-commands.md\`.
5. Use \`./.automation/scripts/aira-memory finish\` after implementation or review when durable memory should change.

## Gates
- Task classification comes before implementation.
- Accepted plans must define exact references, write-scope, forbidden moves, verification surface, success criteria, and slice restrictions.
- Extraction may be automated.
- Promotion is never implicit.
- Repo canon updates require controller approval.
- Audit findings override stale assumptions.

## Slice Completion
- A slice is incomplete if verification is missing.
- A slice is incomplete if \`implement.result.md\` is missing.
- A slice is incomplete if actual file changes escaped the accepted write-scope without explicit approval.
EOF

  ln -snf "$CORE_ROOT/.project-memory/canon/controller-worker-contract.md" "$state_root/.project-memory/canon/controller-worker-contract.md"

  seed_file_if_missing "$state_root/.project-memory/verify-commands.md" <<'EOF'
---
kind: verification-commands
version: 5
---

# Verification Commands

## Frontend
- No frontend verification commands are registered yet.

## Backend
- No backend verification commands are registered yet.

## Notes
- Add only commands that are real, repeatable, and already supported by this repository.
- Until commands are curated here, do not imply green verification.
EOF

  seed_file_if_missing "$state_root/.project-memory/docs-index.md" <<'EOF'
---
kind: docs-index
version: 5
---

# Docs Index

## Framework Docs
- None registered yet.

## Local Docs
- None registered yet.

## Retrieval Rule
- Add only version-specific, non-obvious documentation pointers that the worker cannot recover reliably from code and config alone.
EOF

  ln -snf "$CORE_ROOT/.project-memory/playbooks" "$state_root/.project-memory/playbooks"
  ln -snf "$CORE_ROOT/.project-memory/templates" "$state_root/.project-memory/templates"
  ln -snf "$CORE_ROOT/.project-memory/memory-contract.yaml" "$state_root/.project-memory/memory-contract.yaml"
  ln -snf "$CORE_ROOT/.project-memory/retrieval-map.yaml" "$state_root/.project-memory/retrieval-map.yaml"

  ln -snf "$CORE_ROOT/.automation/scripts" "$state_root/.automation/scripts"
  ln -snf "$CORE_ROOT/.automation/memory-v3" "$state_root/.automation/memory-v3"
  if [[ ! -f "$state_root/.automation/workspace/.gitignore" ]]; then
    cp "$CORE_ROOT/.automation/workspace/.gitignore" "$state_root/.automation/workspace/.gitignore"
  fi
  if [[ ! -f "$state_root/.automation/workspace/.gitkeep" ]]; then
    cp "$CORE_ROOT/.automation/workspace/.gitkeep" "$state_root/.automation/workspace/.gitkeep"
  fi

  ln -snf "$CORE_ROOT/.claude/agents" "$state_root/.claude/agents"
}

write_metadata() {
  local repo_root="$1"
  local state_root="$2"
  local repo_id
  local worktree_id
  repo_id="$(repo_id_for "$repo_root")"
  worktree_id="$(worktree_id_for "$repo_root")"
  mkdir -p "$state_root"
  cat >"$state_root/metadata.json" <<EOF
{
  "mode": "memory-core-v5-user-level",
  "project_name": "$(printf '%s' "$(project_name_for "$repo_root")")",
  "repo_root": "$(printf '%s' "$repo_root")",
  "repo_id": "$(printf '%s' "$repo_id")",
  "worktree_id": "$(printf '%s' "$worktree_id")",
  "common_git_dir": "$(printf '%s' "$(git_common_dir "$repo_root")")",
  "git_dir": "$(printf '%s' "$(git_dir_path "$repo_root")")",
  "branch": "$(printf '%s' "$(git_branch_name "$repo_root")")",
  "attached_at": "$(date +%FT%T%z)"
}
EOF
}

attach_repo() {
  local repo_arg="$1"
  require_core
  local repo_root
  local state_root
  repo_root="$(git_top "$repo_arg")"
  state_root="$(managed_state_root_from_repo "$repo_root" || true)"
  if [[ -z "$state_root" ]]; then
    state_root="$(state_root_for "$repo_root")"
  fi

  preflight_attach "$repo_root" "$state_root"

  render_state_files "$repo_root" "$state_root"
  write_metadata "$repo_root" "$state_root"

  ensure_symlink "$state_root/AGENTS.md" "$repo_root/AGENTS.md"
  ensure_symlink "$state_root/.project-memory" "$repo_root/.project-memory"
  ensure_symlink "$state_root/.automation" "$repo_root/.automation"
  ensure_symlink "$state_root/.claude" "$repo_root/.claude"
  ensure_git_exclude "$repo_root"

  cat <<EOF
attached_repo=$repo_root
state_root=$state_root
controller_agent=$repo_root/.claude/agents/aira-controller.md
operator_cli=$repo_root/.automation/scripts/aira-memory
EOF
}

detach_repo() {
  local repo_arg="$1"
  local repo_root
  repo_root="$(git_top "$repo_arg")"
  remove_git_exclude "$repo_root"
  for path in "$repo_root/AGENTS.md" "$repo_root/.project-memory" "$repo_root/.automation" "$repo_root/.claude"; do
    if [[ -L "$path" ]]; then
      rm "$path"
    fi
  done
  printf 'detached_repo=%s\n' "$repo_root"
}

status_repo() {
  local repo_arg="$1"
  local repo_root
  local attached_state_root
  local state_root
  repo_root="$(git_top "$repo_arg")"
  attached_state_root="$(managed_state_root_from_repo "$repo_root" || true)"
  state_root="$attached_state_root"
  if [[ -z "$state_root" ]]; then
    state_root="$(state_root_for "$repo_root")"
  fi
  cat <<EOF
repo_root=$repo_root
repo_id=$(repo_id_for "$repo_root")
worktree_id=$(worktree_id_for "$repo_root")
branch=$(git_branch_name "$repo_root")
state_root=$state_root
attached_state_root=$(if [[ -n "$attached_state_root" ]]; then printf '%s' "$attached_state_root"; else printf 'missing'; fi)
agents_link=$(if [[ -L "$repo_root/.claude" ]]; then readlink "$repo_root/.claude"; else printf 'missing'; fi)
automation_link=$(if [[ -L "$repo_root/.automation" ]]; then readlink "$repo_root/.automation"; else printf 'missing'; fi)
project_memory_link=$(if [[ -L "$repo_root/.project-memory" ]]; then readlink "$repo_root/.project-memory"; else printf 'missing'; fi)
bootstrap_link=$(if [[ -L "$repo_root/AGENTS.md" ]]; then readlink "$repo_root/AGENTS.md"; else printf 'missing'; fi)
metadata=$(if [[ -f "$state_root/metadata.json" ]]; then printf '%s' "$state_root/metadata.json"; else printf 'missing'; fi)
EOF
}

list_known() {
  mkdir -p "$PROJECTS_ROOT"
  local found="false"
  while IFS= read -r metadata; do
    if metadata_is_attached "$metadata"; then
      found="true"
      cat <<EOF
project_name=$(metadata_value "$metadata" "project_name")
repo_root=$(metadata_value "$metadata" "repo_root")
repo_id=$(metadata_value "$metadata" "repo_id")
worktree_id=$(metadata_value "$metadata" "worktree_id")
state_root=$(dirname "$metadata")
status=attached

EOF
    fi
  done < <(find "$PROJECTS_ROOT" -path '*/worktrees/*/metadata.json' -type f | sort)
  if [[ "$found" == "false" ]]; then
    echo "No attached Memory Core V5 worktrees."
  fi
}

doctor_known() {
  if [[ $# -eq 0 ]]; then
    doctor_home_surface
    return
  fi

  if [[ "${1:-}" != "--repo" || $# -lt 2 ]]; then
    echo "doctor accepts no arguments or --repo <path>" >&2
    exit 1
  fi

  doctor_repo_surface "$(git_top "$2")"
}

prune_known() {
  local apply_mode="${1:-false}"
  mkdir -p "$PROJECTS_ROOT"
  local found="false"
  while IFS= read -r metadata; do
    if metadata_is_attached "$metadata"; then
      continue
    fi
    found="true"
    local state_root
    state_root="$(dirname "$metadata")"
    cat <<EOF
project_name=$(metadata_value "$metadata" "project_name")
repo_root=$(metadata_value "$metadata" "repo_root")
repo_id=$(metadata_value "$metadata" "repo_id")
worktree_id=$(metadata_value "$metadata" "worktree_id")
state_root=$state_root
status=stale
mode=$(if [[ "$apply_mode" == "true" ]]; then printf 'pruned'; else printf 'dry-run'; fi)

EOF
    if [[ "$apply_mode" == "true" ]]; then
      rm -rf "$state_root"
      cleanup_empty_registry_dirs "$state_root"
    fi
  done < <(find "$PROJECTS_ROOT" -path '*/worktrees/*/metadata.json' -type f | sort)
  if [[ "$found" == "false" ]]; then
    if [[ "$apply_mode" == "true" ]]; then
      echo "No stale Memory Core V5 state directories."
    else
      echo "No stale Memory Core V5 state directories to prune."
    fi
  fi
}

if [[ $# -eq 0 ]]; then
  usage >&2
  exit 1
fi

command="$1"
shift

case "$command" in
  attach)
    if [[ "${1:-}" != "--repo" || $# -lt 2 ]]; then
      echo "attach requires --repo <path>" >&2
      exit 1
    fi
    attach_repo "$2"
    ;;
  detach)
    if [[ "${1:-}" != "--repo" || $# -lt 2 ]]; then
      echo "detach requires --repo <path>" >&2
      exit 1
    fi
    detach_repo "$2"
    ;;
  status)
    if [[ "${1:-}" != "--repo" || $# -lt 2 ]]; then
      echo "status requires --repo <path>" >&2
      exit 1
    fi
    status_repo "$2"
    ;;
  doctor)
    doctor_known "$@"
    ;;
  list)
    list_known
    ;;
  prune)
    if [[ "${1:-}" == "--apply" ]]; then
      prune_known true
    elif [[ $# -eq 0 ]]; then
      prune_known false
    else
      echo "prune accepts no arguments or --apply" >&2
      exit 1
    fi
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    echo "Unknown memory-core-user command: $command" >&2
    usage >&2
    exit 1
    ;;
esac
