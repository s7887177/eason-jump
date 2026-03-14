# eason-jump shell integration for Zsh
# Sourced from ~/.zshrc via 'j init'

__EASON_JUMP_CORE="${EASON_JUMP_DATA_DIR:-$HOME/.local/share/eason-jump}/j-core"
__EASON_JUMP_ACTIVE=1
__EASON_JUMP_NAVIGATING=""
__EASON_JUMP_SESSION_ID="$$"

j() {
    local _gflag=""
    local _args=()
    for _a in "$@"; do
        if [ "$_a" = "-g" ]; then
            _gflag="-g"
        else
            _args+=("$_a")
        fi
    done
    set -- "${_args[@]}"

    case "${1:-}" in
        ""|--help|-h)
            "$__EASON_JUMP_CORE" --help
            ;;
        help)
            "$__EASON_JUMP_CORE" help "$2"
            ;;
        activate)
            __EASON_JUMP_ACTIVE=1
            echo "eason-jump: recording activated"
            ;;
        deactivate)
            __EASON_JUMP_ACTIVE=""
            echo "eason-jump: recording deactivated"
            ;;
        b)
            local _target
            _target=$("$__EASON_JUMP_CORE" b "$__EASON_JUMP_SESSION_ID") || return $?
            __EASON_JUMP_NAVIGATING=1
            cd "$_target"
            __EASON_JUMP_NAVIGATING=""
            ;;
        f)
            local _target
            _target=$("$__EASON_JUMP_CORE" f "$__EASON_JUMP_SESSION_ID") || return $?
            __EASON_JUMP_NAVIGATING=1
            cd "$_target"
            __EASON_JUMP_NAVIGATING=""
            ;;
        jump)
            local _target
            _target=$("$__EASON_JUMP_CORE" jump "$2" "$__EASON_JUMP_SESSION_ID") || return $?
            __EASON_JUMP_NAVIGATING=1
            cd "$_target"
            __EASON_JUMP_NAVIGATING=""
            ;;
        create)
            "$__EASON_JUMP_CORE" $_gflag create "$2" "$3" "$__EASON_JUMP_SESSION_ID"
            ;;
        history)
            local _hflags=""
            if [ "$_gflag" = "-g" ]; then
                _hflags="--graph"
            fi
            shift
            for _a in "$@"; do
                if [ "$_a" = "-g" ] || [ "$_a" = "--graph" ]; then
                    _hflags="--graph"
                fi
            done
            local _deact=""
            [ -z "$__EASON_JUMP_ACTIVE" ] && _deact="1"
            if [ -n "$_hflags" ]; then
                "$__EASON_JUMP_CORE" history --graph "$__EASON_JUMP_SESSION_ID" ${_deact:+--deactivated}
            else
                "$__EASON_JUMP_CORE" history "$__EASON_JUMP_SESSION_ID" ${_deact:+--deactivated}
            fi
            ;;
        ls)
            "$__EASON_JUMP_CORE" ls "$__EASON_JUMP_SESSION_ID"
            ;;
        rm)
            "$__EASON_JUMP_CORE" rm "$2" "$__EASON_JUMP_SESSION_ID"
            ;;
        init|deinit|clear|uninstall)
            "$__EASON_JUMP_CORE" "$@"
            ;;
        *)
            if [ -n "${2:-}" ]; then
                "$__EASON_JUMP_CORE" $_gflag "$1" "$2" "$__EASON_JUMP_SESSION_ID"
            elif [ -n "$_gflag" ]; then
                "$__EASON_JUMP_CORE" _promote "$1" "$__EASON_JUMP_SESSION_ID"
            else
                local _target
                _target=$("$__EASON_JUMP_CORE" _resolve "$1" "$__EASON_JUMP_SESSION_ID") || return $?
                __EASON_JUMP_NAVIGATING=1
                cd "$_target"
                __EASON_JUMP_NAVIGATING=""
            fi
            ;;
    esac
}

__eason_jump_cd_hook() {
    if [[ -n "$__EASON_JUMP_ACTIVE" ]] && [[ -z "$__EASON_JUMP_NAVIGATING" ]]; then
        "$__EASON_JUMP_CORE" _record "$PWD" "$__EASON_JUMP_SESSION_ID" 2>/dev/null || true
    fi
}

# Install the cd hook via chpwd
autoload -Uz add-zsh-hook
add-zsh-hook chpwd __eason_jump_cd_hook
