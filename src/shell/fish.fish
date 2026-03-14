# eason-jump shell integration for Fish
# Sourced from Fish config via 'j init'

set -g __EASON_JUMP_CORE (string replace -r '/$' '' -- (set -q EASON_JUMP_DATA_DIR; and echo $EASON_JUMP_DATA_DIR; or echo $HOME/.local/share/eason-jump))"/j-core"
set -g __EASON_JUMP_ACTIVE 1
set -g __EASON_JUMP_NAVIGATING ""
set -g __EASON_JUMP_SESSION_ID $fish_pid

function j
    if test (count $argv) -eq 0; or test "$argv[1]" = "--help"; or test "$argv[1]" = "-h"
        command "$__EASON_JUMP_CORE" --help
        return
    end

    # Parse -g flag
    set -l gflag
    set -l args
    for a in $argv
        if test "$a" = "-g"
            set gflag "-g"
        else
            set -a args "$a"
        end
    end

    switch $args[1]
        case help
            if test (count $args) -ge 2
                command "$__EASON_JUMP_CORE" help "$args[2]"
            else
                command "$__EASON_JUMP_CORE" help
            end
        case activate
            set -g __EASON_JUMP_ACTIVE 1
            echo "eason-jump: recording activated"
        case deactivate
            set -g __EASON_JUMP_ACTIVE ""
            echo "eason-jump: recording deactivated"
        case b
            set -l _target (command "$__EASON_JUMP_CORE" b "$__EASON_JUMP_SESSION_ID")
            or return $status
            set -g __EASON_JUMP_NAVIGATING 1
            cd "$_target"
            set -g __EASON_JUMP_NAVIGATING ""
        case f
            set -l _target (command "$__EASON_JUMP_CORE" f "$__EASON_JUMP_SESSION_ID")
            or return $status
            set -g __EASON_JUMP_NAVIGATING 1
            cd "$_target"
            set -g __EASON_JUMP_NAVIGATING ""
        case jump
            set -l _target (command "$__EASON_JUMP_CORE" jump "$args[2]" "$__EASON_JUMP_SESSION_ID")
            or return $status
            set -g __EASON_JUMP_NAVIGATING 1
            cd "$_target"
            set -g __EASON_JUMP_NAVIGATING ""
        case create
            command "$__EASON_JUMP_CORE" $gflag create "$args[2]" "$args[3]" "$__EASON_JUMP_SESSION_ID"
        case history
            set -l hflags
            if test -n "$gflag"
                set hflags "--graph"
            end
            for a in $args[2..-1]
                if test "$a" = "-g"; or test "$a" = "--graph"
                    set hflags "--graph"
                end
            end
            set -l deact_flag
            if test -z "$__EASON_JUMP_ACTIVE"
                set deact_flag "--deactivated"
            end
            if test -n "$hflags"
                command "$__EASON_JUMP_CORE" history --graph "$__EASON_JUMP_SESSION_ID" $deact_flag
            else
                command "$__EASON_JUMP_CORE" history "$__EASON_JUMP_SESSION_ID" $deact_flag
            end
        case ls
            command "$__EASON_JUMP_CORE" ls "$__EASON_JUMP_SESSION_ID"
        case rm
            command "$__EASON_JUMP_CORE" rm "$args[2]" "$__EASON_JUMP_SESSION_ID"
        case init deinit clear uninstall
            command "$__EASON_JUMP_CORE" $args
        case '*'
            if test (count $args) -ge 2
                command "$__EASON_JUMP_CORE" $gflag "$args[1]" "$args[2]" "$__EASON_JUMP_SESSION_ID"
            else if test -n "$gflag"
                command "$__EASON_JUMP_CORE" _promote "$args[1]" "$__EASON_JUMP_SESSION_ID"
            else
                set -l _target (command "$__EASON_JUMP_CORE" _resolve "$args[1]" "$__EASON_JUMP_SESSION_ID")
                or return $status
                set -g __EASON_JUMP_NAVIGATING 1
                cd "$_target"
                set -g __EASON_JUMP_NAVIGATING ""
            end
    end
end

function __eason_jump_cd_hook --on-variable PWD
    if test -n "$__EASON_JUMP_ACTIVE"; and test -z "$__EASON_JUMP_NAVIGATING"
        command "$__EASON_JUMP_CORE" _record "$PWD" "$__EASON_JUMP_SESSION_ID" 2>/dev/null; or true
    end
end
