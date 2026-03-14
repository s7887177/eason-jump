#!/usr/bin/env sh
set -e

PROJ_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PACK_YAML="$PROJ_DIR/pack.yaml"

# Read name and version from pack.yaml
PKG_NAME=$(grep '^name:' "$PACK_YAML" | awk '{print $2}')
PKG_VERSION=$(grep '^version:' "$PACK_YAML" | awk '{print $2}')

# Build first
sh "$PROJ_DIR/scripts/build.sh"

# Pack
RELEASES_DIR="$PROJ_DIR/build/releases"
mkdir -p "$RELEASES_DIR"

TARBALL="${PKG_NAME}_v${PKG_VERSION}.tar.gz"
tar -czf "$RELEASES_DIR/$TARBALL" -C "$PROJ_DIR/dist" .

echo "pack: $RELEASES_DIR/$TARBALL"
