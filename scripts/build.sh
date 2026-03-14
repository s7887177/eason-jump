#!/usr/bin/env sh
set -e

PROJ_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$PROJ_DIR/dist"
SRC_DIR="$PROJ_DIR/src"

# Clean
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Copy source
cp -r "$SRC_DIR"/* "$DIST_DIR/"

# Make executables
chmod +x "$DIST_DIR/j-core"

echo "build: done → $DIST_DIR"
