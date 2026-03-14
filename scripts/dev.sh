#!/usr/bin/env sh
set -e

PROJ_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEV_DIR="$PROJ_DIR/build/dev"
BIN_DIR="$HOME/.local/bin"

# Initial build
rm -rf "$DEV_DIR"
mkdir -p "$DEV_DIR"
cp -r "$PROJ_DIR/src"/* "$DEV_DIR/"
chmod +x "$DEV_DIR/j-core"

# Symlink j-dev
mkdir -p "$BIN_DIR"
ln -sf "$DEV_DIR/j-core" "$BIN_DIR/j-dev"
echo "dev: j-dev linked to $DEV_DIR/j-core"

# Watch for changes and rebuild
echo "dev: watching src/ for changes... (Ctrl+C to stop)"
if command -v inotifywait >/dev/null 2>&1; then
    while inotifywait -r -e modify,create,delete "$PROJ_DIR/src" 2>/dev/null; do
        echo "dev: rebuilding..."
        rm -rf "$DEV_DIR"
        mkdir -p "$DEV_DIR"
        cp -r "$PROJ_DIR/src"/* "$DEV_DIR/"
        chmod +x "$DEV_DIR/j-core"
        echo "dev: rebuilt"
    done
elif command -v fswatch >/dev/null 2>&1; then
    fswatch -o "$PROJ_DIR/src" | while read -r _; do
        echo "dev: rebuilding..."
        rm -rf "$DEV_DIR"
        mkdir -p "$DEV_DIR"
        cp -r "$PROJ_DIR/src"/* "$DEV_DIR/"
        chmod +x "$DEV_DIR/j-core"
        echo "dev: rebuilt"
    done
else
    echo "dev: no file watcher found (install inotify-tools or fswatch)"
    echo "dev: running without watch — rebuild manually with 'make dev'"
fi
