#!/usr/bin/env bash

set -euo pipefail

BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD_DIR="$BUNDLE_DIR/payload"

INSTALL_HOME="${HOME}/.memory-core"
BIN_DIR="${HOME}/.local/bin"
INSTALL_BIN_LINK="true"

expand_user_path() {
  local raw="$1"
  printf '%s\n' "${raw/#\~/$HOME}"
}

canonical_target_path() {
  local raw
  local parent
  raw="$(expand_user_path "$1")"
  if [[ "$raw" != /* ]]; then
    raw="$PWD/$raw"
  fi
  parent="$(dirname "$raw")"
  mkdir -p "$parent"
  parent="$(cd "$parent" && pwd)"
  printf '%s\n' "$parent/$(basename "$raw")"
}

usage() {
  cat <<'EOF'
Usage:
  ./install-memory-core-user.sh [--home <path>] [--bin-dir <path>] [--no-bin-link]

Options:
  --home <path>       User-level Memory Core home. Default: ~/.memory-core
  --bin-dir <path>    Bin directory for the launcher symlink. Default: ~/.local/bin
  --no-bin-link       Do not create a launcher symlink in the bin directory
  -h, --help          Show this help
EOF
}

resolve_payload_dir() {
  if [[ -d "$PAYLOAD_DIR/.project-memory" && -d "$PAYLOAD_DIR/.automation" && -d "$PAYLOAD_DIR/.claude" ]]; then
    printf '%s\n' "$PAYLOAD_DIR"
    return 0
  fi

  if [[ -d "$BUNDLE_DIR/.project-memory" && -d "$BUNDLE_DIR/.automation" && -d "$BUNDLE_DIR/.claude" ]]; then
    printf '%s\n' "$BUNDLE_DIR"
    return 0
  fi

  echo "Unable to locate payload assets next to installer: $BUNDLE_DIR" >&2
  exit 1
}

backup_if_exists() {
  local path="$1"
  if [[ -e "$path" || -L "$path" ]]; then
    local backup="${path}.bak.$(date +%Y%m%d-%H%M%S)"
    mv "$path" "$backup"
    printf 'backed_up=%s\n' "$backup"
  fi
}

copy_tree() {
  local source="$1"
  local destination="$2"
  mkdir -p "$(dirname "$destination")"
  backup_if_exists "$destination"
  cp -R "$source" "$destination"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --home)
      INSTALL_HOME="${2:?missing value for --home}"
      shift 2
      ;;
    --bin-dir)
      BIN_DIR="${2:?missing value for --bin-dir}"
      shift 2
      ;;
    --no-bin-link)
      INSTALL_BIN_LINK="false"
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

INSTALL_HOME="$(canonical_target_path "$INSTALL_HOME")"
BIN_DIR="$(canonical_target_path "$BIN_DIR")"

PAYLOAD_DIR="$(resolve_payload_dir)"

mkdir -p "$INSTALL_HOME/core" "$INSTALL_HOME/bin" "$INSTALL_HOME/projects"

copy_tree "$PAYLOAD_DIR/.project-memory" "$INSTALL_HOME/core/.project-memory"
copy_tree "$PAYLOAD_DIR/.automation" "$INSTALL_HOME/core/.automation"
copy_tree "$PAYLOAD_DIR/.claude" "$INSTALL_HOME/core/.claude"
copy_tree "$BUNDLE_DIR/README.md" "$INSTALL_HOME/README.md"
copy_tree "$BUNDLE_DIR/scripts/memory-core-user.sh" "$INSTALL_HOME/bin/memory-core-user"

find "$INSTALL_HOME/core" -name '._*' -delete
find "$INSTALL_HOME/core" -type d -name '__pycache__' -prune -exec rm -rf {} +
find "$INSTALL_HOME/core" -type f -name '*.pyc' -delete
find "$INSTALL_HOME/bin" -name '._*' -delete

chmod +x "$INSTALL_HOME/bin/memory-core-user"
find "$INSTALL_HOME/core/.automation/scripts" -maxdepth 1 -type f -exec chmod +x {} +

cat >"$INSTALL_HOME/install-manifest.json" <<EOF
{
  "product": "memory-core",
  "bundle_version": "5",
  "install_mode": "user-level",
  "install_home": "$(printf '%s' "$INSTALL_HOME")",
  "core_root": "$(printf '%s' "$INSTALL_HOME/core")",
  "launcher": "$(printf '%s' "$INSTALL_HOME/bin/memory-core-user")"
}
EOF

if [[ "$INSTALL_BIN_LINK" == "true" ]]; then
  mkdir -p "$BIN_DIR"
  backup_if_exists "$BIN_DIR/memory-core-user"
  ln -s "$INSTALL_HOME/bin/memory-core-user" "$BIN_DIR/memory-core-user"
fi

cat <<EOF
installed_home=$INSTALL_HOME
core_root=$INSTALL_HOME/core
launcher=$INSTALL_HOME/bin/memory-core-user
bin_link=$(if [[ "$INSTALL_BIN_LINK" == "true" ]]; then printf '%s' "$BIN_DIR/memory-core-user"; else printf 'disabled'; fi)
default_attach_command=memory-core-user attach --repo /absolute/path/to/worktree
EOF
