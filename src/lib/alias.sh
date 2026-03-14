# alias.sh — alias CRUD functions
# Sourced by j-core. Expects DATA_DIR and RESERVED_COMMANDS to be set.
#
# Two alias scopes:
#   $DATA_DIR/aliases                   — global aliases (persist across sessions)
#   $DATA_DIR/sessions/<sid>.aliases    — session aliases (per-session)
#
# Format: name=path (one per line)
# Resolution order: session > global

_global_file() {
    echo "$DATA_DIR/aliases"
}

_session_file() {
    _sid="${1:-}"
    if [ -z "$_sid" ]; then
        echo ""
        return
    fi
    echo "$DATA_DIR/sessions/${_sid}.aliases"
}

# Get alias — session first, then global
alias_get() {
    _name="$1"
    _sid="${2:-}"

    # Try session first
    _sf=$(_session_file "$_sid")
    if [ -n "$_sf" ] && [ -f "$_sf" ]; then
        _path=$(grep "^${_name}=" "$_sf" 2>/dev/null | head -1 | cut -d= -f2-)
        if [ -n "$_path" ]; then
            printf '%s\n' "$_path"
            return 0
        fi
    fi

    # Then global
    _gf=$(_global_file)
    if [ -f "$_gf" ]; then
        _path=$(grep "^${_name}=" "$_gf" 2>/dev/null | head -1 | cut -d= -f2-)
        if [ -n "$_path" ]; then
            printf '%s\n' "$_path"
            return 0
        fi
    fi

    echo "alias '$_name' not found" >&2
    return 1
}

_validate_alias_name() {
    _name="$1"

    for _cmd in $RESERVED_COMMANDS; do
        if [ "$_name" = "$_cmd" ]; then
            echo "error: '$_name' is a reserved command and cannot be used as an alias" >&2
            return 1
        fi
    done

    case "$_name" in
        *=*)
            echo "error: alias name cannot contain '='" >&2
            return 1
            ;;
    esac
    return 0
}

_write_alias() {
    _file="$1"
    _name="$2"
    _path="$3"

    mkdir -p "$(dirname "$_file")"

    # Remove existing entry if present
    if [ -f "$_file" ]; then
        _tmp=$(grep -v "^${_name}=" "$_file" || true)
        printf '%s\n' "$_tmp" > "$_file"
    fi
    printf '%s=%s\n' "$_name" "$_path" >> "$_file"
    # Clean up empty lines
    _tmp=$(sed '/^$/d' "$_file")
    printf '%s\n' "$_tmp" > "$_file"
}

_remove_from_file() {
    _file="$1"
    _name="$2"
    if [ -f "$_file" ] && grep -q "^${_name}=" "$_file"; then
        _tmp=$(grep -v "^${_name}=" "$_file" || true)
        printf '%s\n' "$_tmp" > "$_file"
        _tmp=$(sed '/^$/d' "$_file")
        printf '%s\n' "$_tmp" > "$_file"
        return 0
    fi
    return 1
}

# alias_set <name> <path> <session_id> [--global]
alias_set() {
    _name="$1"
    _path="$2"
    _sid="${3:-}"
    _global="${4:-}"

    _validate_alias_name "$_name" || return 1

    # Resolve to absolute path
    _path=$(cd "$_path" 2>/dev/null && pwd) || {
        echo "error: '$2' is not a valid directory" >&2
        return 1
    }

    if [ "$_global" = "--global" ]; then
        # Global: also remove session alias if it exists (per spec)
        _sf=$(_session_file "$_sid")
        if [ -n "$_sf" ]; then
            _remove_from_file "$_sf" "$_name" 2>/dev/null || true
        fi
        _write_alias "$(_global_file)" "$_name" "$_path"
        echo "saved (global): $_name → $_path"
    else
        # Session alias
        if [ -z "$_sid" ]; then
            echo "error: no session id (is eason-jump initialized?)" >&2
            return 1
        fi
        _write_alias "$(_session_file "$_sid")" "$_name" "$_path"
        echo "saved: $_name → $_path"
    fi
}

# Remove alias — try session first, then global
alias_rm() {
    _name="$1"
    _sid="${2:-}"

    _sf=$(_session_file "$_sid")
    if [ -n "$_sf" ] && _remove_from_file "$_sf" "$_name"; then
        echo "removed (session): $_name"
        return 0
    fi

    if _remove_from_file "$(_global_file)" "$_name"; then
        echo "removed (global): $_name"
        return 0
    fi

    echo "alias '$_name' not found" >&2
    return 1
}

# Promote session alias to global
alias_promote() {
    _name="$1"
    _sid="${2:-}"

    _sf=$(_session_file "$_sid")
    if [ -z "$_sf" ] || [ ! -f "$_sf" ]; then
        echo "error: no session alias '$_name' to promote" >&2
        return 1
    fi
    _path=$(grep "^${_name}=" "$_sf" 2>/dev/null | head -1 | cut -d= -f2-)
    if [ -z "$_path" ]; then
        echo "error: session alias '$_name' not found" >&2
        return 1
    fi
    _remove_from_file "$_sf" "$_name"
    _write_alias "$(_global_file)" "$_name" "$_path"
    echo "promoted to global: $_name → $_path"
}

# List aliases — merged, showing type, aligned columns
alias_list() {
    _sid="${1:-}"
    _gf=$(_global_file)
    _sf=$(_session_file "$_sid")

    # Collect entries as "type name path" lines
    _entries=""

    if [ -f "$_gf" ] && [ -s "$_gf" ]; then
        while IFS='=' read -r _n _p; do
            [ -z "$_n" ] && continue
            _entries="${_entries}global	${_n}	${_p}
"
        done < "$_gf"
    fi

    if [ -n "$_sf" ] && [ -f "$_sf" ] && [ -s "$_sf" ]; then
        while IFS='=' read -r _n _p; do
            [ -z "$_n" ] && continue
            _entries="${_entries}session	${_n}	${_p}
"
        done < "$_sf"
    fi

    if [ -z "$_entries" ]; then
        return 0
    fi

    printf '%s' "$_entries" | awk -F'\t' '
    {
        types[NR] = $1
        names[NR] = $2
        paths[NR] = $3
        if (length($1) > mt) mt = length($1)
        if (length($2) > mn) mn = length($2)
        count = NR
    }
    END {
        for (i = 1; i <= count; i++) {
            printf "%-" mt "s  %-" mn "s  %s\n", types[i], names[i], paths[i]
        }
    }
    '
}
