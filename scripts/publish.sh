#!/usr/bin/env sh
set -e

PROJ_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PACK_YAML="$PROJ_DIR/pack.yaml"

PKG_NAME=$(grep '^name:' "$PACK_YAML" | awk '{print $2}')
PKG_VERSION=$(grep '^version:' "$PACK_YAML" | awk '{print $2}')
GH_USER=$(gh api user --jq .login)
REPO="$GH_USER/eason-jump"

# Pack first
sh "$PROJ_DIR/scripts/pack.sh"

TARBALL="$PROJ_DIR/build/releases/${PKG_NAME}_v${PKG_VERSION}.tar.gz"

echo "publish: creating release v${PKG_VERSION} on $REPO..."
gh release create "v${PKG_VERSION}" \
    "$TARBALL" \
    "$PROJ_DIR/scripts/install.sh" \
    --repo "$REPO" \
    --title "v${PKG_VERSION}" \
    --notes "Release v${PKG_VERSION}"

echo "publish: done"
