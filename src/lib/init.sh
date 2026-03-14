# init.sh — init/deinit logic
# Sourced by j-core. Expects DATA_DIR and SCRIPT_DIR to be set.

MARKER="# eason-jump"

_detect_parent_shell() {
    # Try to detect the shell that invoked j-core
    _parent_pid=$(ps -o ppid= -p $$ 2>/dev/null | tr -d ' ')
    if [ -n "$_parent_pid" ]; then
        _parent_cmd=$(ps -o comm= -p "$_parent_pid" 2>/dev/null | tr -d ' ')
        case "$_parent_cmd" in
            bash)  echo "bash" ;;
            zsh)   echo "zsh" ;;
            fish)  echo "fish" ;;
            *)     echo "bash" ;;  # default fallback
        esac
    else
        echo "bash"
    fi
}

_rc_file_for_shell() {
    case "$1" in
        bash) echo "$HOME/.bashrc" ;;
        zsh)  echo "$HOME/.zshrc" ;;
        fish) echo "${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d/eason-jump.fish" ;;
    esac
}

_source_line_for_shell() {
    case "$1" in
        bash) echo "source \"$DATA_DIR/shell/bash.sh\" $MARKER" ;;
        zsh)  echo "source \"$DATA_DIR/shell/zsh.sh\" $MARKER" ;;
        fish) echo "source \"$DATA_DIR/shell/fish.fish\" $MARKER" ;;
    esac
}

do_init() {
    _shell=$(_detect_parent_shell)
    _rc=$(_rc_file_for_shell "$_shell")
    _line=$(_source_line_for_shell "$_shell")

    # Guard against duplicate
    if [ -f "$_rc" ] && grep -qF "$MARKER" "$_rc"; then
        echo "eason-jump is already initialized in $_rc"
        return 0
    fi

    # Ensure rc file directory exists (for fish)
    mkdir -p "$(dirname "$_rc")"

    printf '\n%s\n' "$_line" >> "$_rc"
    echo "eason-jump initialized for $_shell (added to $_rc)"
    echo "Restart your shell or run: source $_rc"
}

do_deinit() {
    # Remove from all known rc files
    for _shell in bash zsh fish; do
        _rc=$(_rc_file_for_shell "$_shell")
        if [ -f "$_rc" ] && grep -qF "$MARKER" "$_rc"; then
            _tmp=$(grep -vF "$MARKER" "$_rc")
            printf '%s\n' "$_tmp" > "$_rc"
            echo "eason-jump removed from $_rc"
        fi
    done
}

do_uninstall() {
    do_deinit
    # Remove the install directory (scripts only, not data)
    rm -f "$HOME/.local/bin/j"
    # Remove shell files but keep aliases and sessions (per spec: "without cleanup history")
    rm -rf "$DATA_DIR/shell"
    rm -rf "$DATA_DIR/j-core"
    rm -rf "$DATA_DIR/lib"
    echo "eason-jump uninstalled. Alias and history data preserved in $DATA_DIR"
}
