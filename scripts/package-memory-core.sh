#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/output"
BUNDLE_NAME="memory-core.bundle"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/package-memory-core.sh [--bundle-name <name>]

Options:
  --bundle-name <name>   Output bundle directory and archive basename
  -h, --help             Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bundle-name)
      BUNDLE_NAME="${2:?missing value for --bundle-name}"
      shift 2
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

if [[ -z "$BUNDLE_NAME" ]]; then
  echo "Bundle name must not be empty" >&2
  exit 1
fi

if [[ "$BUNDLE_NAME" == *"/"* || "$BUNDLE_NAME" == "." || "$BUNDLE_NAME" == ".." ]]; then
  echo "Bundle name must be a plain file/directory name: $BUNDLE_NAME" >&2
  exit 1
fi

BUNDLE_DIR="$OUTPUT_DIR/$BUNDLE_NAME"
PAYLOAD_DIR="$BUNDLE_DIR/payload"
ARCHIVE_PATH="$OUTPUT_DIR/$BUNDLE_NAME.tar.gz"
MANIFEST_PATH="$BUNDLE_DIR/bundle-manifest.json"

mkdir -p "$BUNDLE_DIR/scripts" "$PAYLOAD_DIR"

cp "$ROOT_DIR/README.md" "$BUNDLE_DIR/README.md"
cp "$ROOT_DIR/install-memory-core.sh" "$BUNDLE_DIR/install-memory-core.sh"
cp "$ROOT_DIR/scripts/package-memory-core.sh" "$BUNDLE_DIR/scripts/package-memory-core.sh"

rm -rf "$PAYLOAD_DIR/.project-memory" "$PAYLOAD_DIR/.automation" "$PAYLOAD_DIR/.claude"
cp -R "$ROOT_DIR/.project-memory" "$PAYLOAD_DIR/.project-memory"
cp -R "$ROOT_DIR/.automation" "$PAYLOAD_DIR/.automation"
cp -R "$ROOT_DIR/.claude" "$PAYLOAD_DIR/.claude"

rm -rf "$PAYLOAD_DIR/.automation/workspace"
mkdir -p "$PAYLOAD_DIR/.automation/workspace"
cp "$ROOT_DIR/.automation/workspace/.gitkeep" "$PAYLOAD_DIR/.automation/workspace/.gitkeep"
cp "$ROOT_DIR/.automation/workspace/.gitignore" "$PAYLOAD_DIR/.automation/workspace/.gitignore"

find "$PAYLOAD_DIR" -type d -name '__pycache__' -prune -exec rm -rf {} +
find "$PAYLOAD_DIR" -type f -name '*.pyc' -delete
find "$PAYLOAD_DIR" -name '._*' -delete

find "$PAYLOAD_DIR/.automation/scripts" -maxdepth 1 -type f -exec chmod +x {} +
chmod +x "$BUNDLE_DIR/install-memory-core.sh" "$BUNDLE_DIR/scripts/package-memory-core.sh"

printf '{\n' >"$MANIFEST_PATH"
printf '  "bundle_name": %s,\n' "\"$BUNDLE_NAME\"" >>"$MANIFEST_PATH"
printf '  "product": "memory-core",\n' >>"$MANIFEST_PATH"
printf '  "bundle_version": "4",\n' >>"$MANIFEST_PATH"
printf '  "installer": "install-memory-core.sh",\n' >>"$MANIFEST_PATH"
printf '  "builder": "scripts/package-memory-core.sh",\n' >>"$MANIFEST_PATH"
printf '  "default_install_mode": "repo-local-only",\n' >>"$MANIFEST_PATH"
printf '  "included_assets": [\n' >>"$MANIFEST_PATH"
printf '    "AGENTS.md",\n' >>"$MANIFEST_PATH"
printf '    ".project-memory",\n' >>"$MANIFEST_PATH"
printf '    ".automation",\n' >>"$MANIFEST_PATH"
printf '    ".claude/agents"\n' >>"$MANIFEST_PATH"
printf '  ],\n' >>"$MANIFEST_PATH"
printf '  "optional_integrations": [\n' >>"$MANIFEST_PATH"
printf '    "codex-global-skills",\n' >>"$MANIFEST_PATH"
printf '    "obsidian-sync",\n' >>"$MANIFEST_PATH"
printf '    "provider-adapters"\n' >>"$MANIFEST_PATH"
printf '  ]\n' >>"$MANIFEST_PATH"
printf '}\n' >>"$MANIFEST_PATH"

rm -f "$ARCHIVE_PATH"
COPYFILE_DISABLE=1 tar -czf "$ARCHIVE_PATH" -C "$OUTPUT_DIR" "$BUNDLE_NAME"
printf '%s\n' "$ARCHIVE_PATH"
