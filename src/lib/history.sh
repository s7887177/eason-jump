# history.sh — session history with branching graph
# Sourced by j-core. Expects SESSIONS_DIR, DATA_DIR to be set.
#
# Session file format (tab-delimited):
#   H<TAB>node_id                   — HEAD pointer
#   N<TAB>from_id<TAB>to_id         — forward navigation hint (last visited child)
#   P<TAB>node_id<TAB>parent_id<TAB>path  — graph node (parent_id=0 for root)

_history_file() {
    _sid="${1:-$$}"
    echo "$SESSIONS_DIR/$_sid"
}

# Get a field from the session file
_h_get_head() {
    awk -F'\t' '$1=="H"{print $2}' "$1"
}

_h_get_node_path() {
    # $1=file, $2=node_id
    awk -F'\t' -v nid="$2" '$1=="P" && $2==nid{print $4}' "$1"
}

_h_get_node_parent() {
    awk -F'\t' -v nid="$2" '$1=="P" && $2==nid{print $3}' "$1"
}

_h_get_next() {
    # $1=file, $2=from_id → returns to_id
    awk -F'\t' -v fid="$2" '$1=="N" && $2==fid{print $3}' "$1"
}

_h_max_id() {
    awk -F'\t' '$1=="P"{if($2+0>m)m=$2+0}END{print m+0}' "$1"
}

history_push() {
    _path="$1"
    _sid="$2"
    _file=$(_history_file "$_sid")

    if [ ! -f "$_file" ]; then
        # First node: id=1, parent=0
        printf 'H\t1\nP\t1\t0\t%s\n' "$_path" > "$_file"
        return 0
    fi

    _head=$(_h_get_head "$_file")
    if [ -z "$_head" ] || [ "$_head" = "0" ]; then
        printf 'H\t1\nP\t1\t0\t%s\n' "$_path" > "$_file"
        return 0
    fi

    # Don't record if same as current HEAD path
    _cur_path=$(_h_get_node_path "$_file" "$_head")
    if [ "$_cur_path" = "$_path" ]; then
        return 0
    fi

    # Create new node as child of HEAD
    _new_id=$(( $(_h_max_id "$_file") + 1 ))

    # Remove old N line for HEAD (if any), add new one pointing to new node
    _tmp=$(awk -F'\t' -v fid="$_head" '!($1=="N" && $2==fid)' "$_file")
    printf '%s\n' "$_tmp" > "$_file"
    # Update HEAD
    _tmp=$(awk -F'\t' '$1!="H"' "$_file")
    printf 'H\t%s\n%s\nN\t%s\t%s\nP\t%s\t%s\t%s\n' \
        "$_new_id" "$_tmp" "$_head" "$_new_id" "$_new_id" "$_head" "$_path" > "$_file"
}

history_back() {
    _sid="${1:-$$}"
    _file=$(_history_file "$_sid")

    if [ ! -f "$_file" ]; then
        echo "no history" >&2
        return 1
    fi

    _head=$(_h_get_head "$_file")
    _parent=$(_h_get_node_parent "$_file" "$_head")

    if [ -z "$_parent" ] || [ "$_parent" = "0" ]; then
        echo "already at the beginning" >&2
        return 1
    fi

    # Update NEXT hint for parent → HEAD (so forward returns here)
    _tmp=$(awk -F'\t' -v fid="$_parent" '!($1=="N" && $2==fid)' "$_file")
    printf '%s\n' "$_tmp" > "$_file"
    _tmp=$(awk -F'\t' '$1!="H"' "$_file")
    printf 'H\t%s\n%s\nN\t%s\t%s\n' "$_parent" "$_tmp" "$_parent" "$_head" > "$_file"

    _target=$(_h_get_node_path "$_file" "$_parent")
    printf '%s\n' "$_target"
}

history_forward() {
    _sid="${1:-$$}"
    _file=$(_history_file "$_sid")

    if [ ! -f "$_file" ]; then
        echo "no history" >&2
        return 1
    fi

    _head=$(_h_get_head "$_file")
    _next=$(_h_get_next "$_file" "$_head")

    if [ -z "$_next" ]; then
        # Try finding any child of HEAD
        _next=$(awk -F'\t' -v pid="$_head" '$1=="P" && $3==pid{print $2; exit}' "$_file")
    fi

    if [ -z "$_next" ]; then
        echo "already at the end" >&2
        return 1
    fi

    # Move HEAD
    _tmp=$(awk -F'\t' '$1!="H"' "$_file")
    printf 'H\t%s\n%s\n' "$_next" "$_tmp" > "$_file"

    _target=$(_h_get_node_path "$_file" "$_next")
    printf '%s\n' "$_target"
}

# Collect all aliases as "name=path" pairs for graph display
_h_collect_aliases() {
    _sid="${1:-}"
    _result=""
    _gf="$DATA_DIR/aliases"
    if [ -f "$_gf" ] && [ -s "$_gf" ]; then
        while IFS='=' read -r _n _p; do
            [ -z "$_n" ] && continue
            _result="${_result}${_n}=${_p};"
        done < "$_gf"
    fi
    _sf="$DATA_DIR/sessions/${_sid}.aliases"
    if [ -n "$_sid" ] && [ -f "$_sf" ] && [ -s "$_sf" ]; then
        while IFS='=' read -r _n _p; do
            [ -z "$_n" ] && continue
            _result="${_result}${_n}=${_p};"
        done < "$_sf"
    fi
    printf '%s' "$_result"
}

# Display: j history (linear — root to HEAD path only)
history_linear() {
    _sid="${1:-$$}"
    _deactivated="${2:-}"
    _file=$(_history_file "$_sid")

    if [ ! -f "$_file" ]; then
        echo "(no history)"
        return 0
    fi

    _head=$(_h_get_head "$_file")
    _aliases=$(_h_collect_aliases "$_sid")

    awk -F'\t' -v head_id="$_head" -v aliases="$_aliases" -v deactivated="$_deactivated" '
    $1=="P" { node_path[$2] = $4; node_parent[$2] = $3 }
    END {
        YELLOW = deactivated ? "\033[90m" : "\033[33m"
        GREEN  = deactivated ? "\033[90m" : "\033[32m"
        BLUE   = deactivated ? "\033[90m" : "\033[34m"
        GRAY   = "\033[90m"
        RESET  = "\033[0m"
        STAR   = deactivated ? GRAY : ""

        n = split(aliases, apairs, ";")
        for (i = 1; i <= n; i++) {
            if (apairs[i] == "") continue
            eq = index(apairs[i], "=")
            if (eq > 0) {
                aname = substr(apairs[i], 1, eq-1)
                apath = substr(apairs[i], eq+1)
                if (path_alias[apath] != "")
                    path_alias[apath] = path_alias[apath] ", " aname
                else
                    path_alias[apath] = aname
            }
        }

        # Trace path from HEAD to root, then reverse
        count = 0
        cur = head_id + 0
        while (cur != 0 && cur != "" && node_path[cur] != "") {
            count++
            rev[count] = cur
            cur = node_parent[cur] + 0
        }
        if (count == 0) { print "(no history)"; exit }

        # Reverse into display order (root first)
        for (i = 1; i <= count; i++) {
            path_order[i] = rev[count - i + 1]
        }

        if (deactivated) printf GRAY "(recording deactivated)" RESET "\n"

        for (i = 1; i <= count; i++) {
            nid = path_order[i]
            p = node_path[nid]
            ann = ""
            aname = path_alias[p]

            if (nid == head_id + 0) {
                if (aname != "") {
                    if (deactivated) ann = " (" GRAY "HEAD -> " aname RESET ")"
                    else ann = " (" BLUE "HEAD" RESET " -> " GREEN aname RESET ")"
                } else {
                    if (deactivated) ann = " (" GRAY "HEAD" RESET ")"
                    else ann = " (" BLUE "HEAD" RESET ")"
                }
            } else if (aname != "") {
                if (deactivated) ann = " (" GRAY aname RESET ")"
                else ann = " (" GREEN aname RESET ")"
            }

            printf "%s* %s%s%s%s\n", STAR, YELLOW, p, RESET, ann
        }
    }
    ' "$_file"
}

# Display: j history -g (full graph with branches)
history_graph() {
    _sid="${1:-$$}"
    _deactivated="${2:-}"
    _file=$(_history_file "$_sid")

    if [ ! -f "$_file" ]; then
        echo "(no history)"
        return 0
    fi

    _head=$(_h_get_head "$_file")
    _aliases=$(_h_collect_aliases "$_sid")

    awk -F'\t' -v head_id="$_head" -v aliases="$_aliases" -v deactivated="$_deactivated" '
    $1=="P" { node_path[$2] = $4; node_parent[$2] = $3; nodes[++nc] = $2 }
    $1=="N" { next_hint[$2] = $3 }
    END {
        if (deactivated) {
            STAR = "\033[90m"; YELLOW = "\033[90m"; GREEN = "\033[90m"
            BLUE = "\033[90m"; RESET = "\033[0m"; GRAY = "\033[90m"
            for (i = 1; i <= 6; i++) EC[i] = "\033[90m"
        } else {
            STAR = ""; YELLOW = "\033[33m"; GREEN = "\033[32m"
            BLUE = "\033[34m"; RESET = "\033[0m"; GRAY = "\033[90m"
            EC[1] = "\033[31m"; EC[2] = "\033[33m"; EC[3] = "\033[34m"
            EC[4] = "\033[32m"; EC[5] = "\033[35m"; EC[6] = "\033[36m"
        }

        n = split(aliases, apairs, ";")
        for (i = 1; i <= n; i++) {
            if (apairs[i] == "") continue
            eq = index(apairs[i], "=")
            if (eq > 0) {
                aname = substr(apairs[i], 1, eq-1)
                apath = substr(apairs[i], eq+1)
                if (path_alias[apath] != "")
                    path_alias[apath] = path_alias[apath] ", " aname
                else
                    path_alias[apath] = aname
            }
        }

        # Build children lists
        for (i = 1; i <= nc; i++) {
            nid = nodes[i]; pid = node_parent[nid]
            if (pid != 0 && pid != "") {
                child_count[pid]++
                children[pid, child_count[pid]] = nid
            }
        }

        root = 0
        for (i = 1; i <= nc; i++) {
            if (node_parent[nodes[i]] == 0 || node_parent[nodes[i]] == "") {
                root = nodes[i]; break
            }
        }
        if (root == 0) { print "(no history)"; exit }

        if (deactivated) printf GRAY "(recording deactivated)" RESET "\n"

        # Iterative DFS
        # Stack: s_nid, s_col, s_type (0=visit, 1=branch_line)
        sp = 0
        sp++; s_nid[sp] = root; s_col[sp] = 0; s_type[sp] = 0
        max_col = 0

        while (sp > 0) {
            cur_nid = s_nid[sp]; cur_col = s_col[sp]; cur_type = s_type[sp]
            sp--

            if (cur_type == 1) {
                # Branch line: cur_col=parent_col, cur_nid=new_branch_col
                parent_col = cur_col; new_col = cur_nid
                line = ""
                for (c = 0; c < new_col; c++) {
                    ec = EC[(c % 6) + 1]
                    if (c == parent_col) {
                        line = line ec "|" RESET
                    } else if (active[c]) {
                        line = line ec "|" RESET
                    } else {
                        line = line " "
                    }
                    # Separator character
                    if (c == parent_col && c + 1 == new_col) {
                        nec = EC[(new_col % 6) + 1]
                        line = line nec "\\" RESET
                    } else if (c < new_col - 1) {
                        line = line " "
                    }
                }
                print line
                continue
            }

            # Type 0: visit node
            active[cur_col] = 1

            # Find highest active column for prefix width
            render_max = cur_col
            for (c = 0; c <= max_col; c++) {
                if (active[c] && c > render_max) render_max = c
            }

            # Build prefix
            line = ""
            for (c = 0; c <= render_max; c++) {
                ec = EC[(c % 6) + 1]
                if (c == cur_col) {
                    if (STAR != "") line = line STAR "* " RESET
                    else line = line "* "
                } else if (active[c]) {
                    line = line ec "| " RESET
                } else {
                    line = line "  "
                }
            }

            # Annotation
            p = node_path[cur_nid]
            ann = ""
            aname = path_alias[p]
            if (cur_nid == head_id + 0) {
                if (aname != "") {
                    if (deactivated) ann = " (" GRAY "HEAD -> " aname RESET ")"
                    else ann = " (" BLUE "HEAD" RESET " -> " GREEN aname RESET ")"
                } else {
                    if (deactivated) ann = " (" GRAY "HEAD" RESET ")"
                    else ann = " (" BLUE "HEAD" RESET ")"
                }
            } else if (aname != "") {
                if (deactivated) ann = " (" GRAY aname RESET ")"
                else ann = " (" GREEN aname RESET ")"
            }

            printf "%s%s%s%s%s\n", line, YELLOW, p, RESET, ann

            # Handle children
            nkids = child_count[cur_nid] + 0
            if (nkids == 0) {
                active[cur_col] = 0
            } else if (nkids == 1) {
                sp++; s_nid[sp] = children[cur_nid, 1]; s_col[sp] = cur_col; s_type[sp] = 0
            } else {
                # Determine main child (NEXT hint or last child)
                main_child = children[cur_nid, nkids]
                if (next_hint[cur_nid] != "") {
                    for (k = 1; k <= nkids; k++) {
                        if (children[cur_nid, k] == next_hint[cur_nid]) {
                            main_child = next_hint[cur_nid]; break
                        }
                    }
                }

                # Push main child (rendered last = bottom of stack)
                sp++; s_nid[sp] = main_child; s_col[sp] = cur_col; s_type[sp] = 0

                # Push branch children (rendered first)
                for (k = nkids; k >= 1; k--) {
                    kid = children[cur_nid, k]
                    if (kid == main_child) continue
                    max_col++
                    new_col = max_col
                    # Do NOT set active[new_col] here — let the visit handler do it
                    sp++; s_nid[sp] = kid; s_col[sp] = new_col; s_type[sp] = 0
                    sp++; s_nid[sp] = new_col; s_col[sp] = cur_col; s_type[sp] = 1
                }
            }
        }
    }
    ' "$_file"
}

history_clear() {
    rm -rf "$SESSIONS_DIR"
    mkdir -p "$SESSIONS_DIR"
    echo "history cleared"
}
