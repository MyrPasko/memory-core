#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/output"
BUNDLE_NAME="memory-v3-bundle"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/package-memory-v3.sh [--bundle-name <name>]

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

mkdir -p "$BUNDLE_DIR/scripts" "$PAYLOAD_DIR"

cp "$ROOT_DIR/README.md" "$BUNDLE_DIR/README.md"
cp "$ROOT_DIR/install-memory-v3.sh" "$BUNDLE_DIR/install-memory-v3.sh"
cp "$ROOT_DIR/scripts/package-memory-v3.sh" "$BUNDLE_DIR/scripts/package-memory-v3.sh"

rm -rf "$PAYLOAD_DIR/.project-memory" "$PAYLOAD_DIR/.automation"
cp -R "$ROOT_DIR/.project-memory" "$PAYLOAD_DIR/.project-memory"
cp -R "$ROOT_DIR/.automation" "$PAYLOAD_DIR/.automation"

rm -rf "$PAYLOAD_DIR/.automation/workspace"
mkdir -p "$PAYLOAD_DIR/.automation/workspace"
cp "$ROOT_DIR/.automation/workspace/.gitkeep" "$PAYLOAD_DIR/.automation/workspace/.gitkeep"
cp "$ROOT_DIR/.automation/workspace/.gitignore" "$PAYLOAD_DIR/.automation/workspace/.gitignore"

find "$PAYLOAD_DIR" -type d -name '__pycache__' -prune -exec rm -rf {} +
find "$PAYLOAD_DIR" -type f -name '*.pyc' -delete
find "$PAYLOAD_DIR" -name '._*' -delete

find "$PAYLOAD_DIR/.automation/scripts" -maxdepth 1 -type f -exec chmod +x {} +
chmod +x "$BUNDLE_DIR/install-memory-v3.sh" "$BUNDLE_DIR/scripts/package-memory-v3.sh"

rm -f "$ARCHIVE_PATH"
COPYFILE_DISABLE=1 tar -czf "$ARCHIVE_PATH" -C "$OUTPUT_DIR" "$BUNDLE_NAME"
printf '%s\n' "$ARCHIVE_PATH"
