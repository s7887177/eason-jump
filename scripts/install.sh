#!/usr/bin/env sh
set -e

INSTALL_DIR="$HOME/.local/share/eason-jump"
BIN_DIR="$HOME/.local/bin"

install_from_local() {
    PROJ_DIR="$1"
    echo "install: building from source..."
    sh "$PROJ_DIR/scripts/build.sh"

    echo "install: copying to $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"
    rm -rf "$INSTALL_DIR/j-core" "$INSTALL_DIR/lib" "$INSTALL_DIR/shell"
    cp "$PROJ_DIR/dist/j-core" "$INSTALL_DIR/j-core"
    cp -r "$PROJ_DIR/dist/lib" "$INSTALL_DIR/lib"
    cp -r "$PROJ_DIR/dist/shell" "$INSTALL_DIR/shell"
}

install_from_remote() {
    echo "install: fetching latest release..."
    TMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_DIR"' EXIT

    REPO_URL="https://github.com/s7887177/eason-jump"
    TARBALL_URL="$REPO_URL/releases/latest/download/eason-jump.tar.gz"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$TARBALL_URL" -o "$TMP_DIR/eason-jump.tar.gz" || {
            echo "error: could not download release from $TARBALL_URL" >&2
            exit 1
        }
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$TARBALL_URL" -O "$TMP_DIR/eason-jump.tar.gz" || {
            echo "error: could not download release from $TARBALL_URL" >&2
            exit 1
        }
    else
        echo "error: neither 'curl' nor 'wget' found" >&2
        exit 1
    fi

    mkdir -p "$INSTALL_DIR"
    rm -rf "$INSTALL_DIR/j-core" "$INSTALL_DIR/lib" "$INSTALL_DIR/shell"
    tar -xzf "$TMP_DIR/eason-jump.tar.gz" -C "$INSTALL_DIR"
}

# Detect if we're in the project directory
SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
PROJ_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"

if [ -f "$PROJ_DIR/pack.yaml" ] && grep -q "^name: eason-jump" "$PROJ_DIR/pack.yaml" 2>/dev/null; then
    install_from_local "$PROJ_DIR"
else
    install_from_remote
fi

chmod +x "$INSTALL_DIR/j-core"
mkdir -p "$BIN_DIR"
ln -sf "$INSTALL_DIR/j-core" "$BIN_DIR/j"
j init
echo "install: done."