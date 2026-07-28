#!/bin/bash
# Per-session caveman flag for the statusline.
#
# The caveman plugin keeps one global flag (~/.claude/.caveman-active) shared
# by every session, so parallel sessions overwrite each other's level. This
# hook mirrors the plugin's mode parsing but writes one flag per session:
#   ~/.claude/.caveman-session-<session_id>
# statusline.sh prefers the per-session flag and falls back to the global one.
#
# Register for SessionStart (seed default level, prune stale flags) and
# UserPromptSubmit (track /caveman commands and natural-language switches).
# Needs jq.

STALE_FLAG_DAYS=7

input=$(cat)

session_id=$(echo "$input" | jq -r '.session_id // empty')
event=$(echo "$input" | jq -r '.hook_event_name // empty')

# The session id lands in a file name. Refuse anything but plain uuid chars.
case "$session_id" in
    ""|*[!A-Za-z0-9-]*) exit 0 ;;
esac

flag_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
session_flag="$flag_dir/.caveman-session-$session_id"

valid_mode() {
    case "$1" in
        off|lite|full|ultra|wenyan|wenyan-lite|wenyan-full|wenyan-ultra|commit|review|compress)
            return 0 ;;
        *)
            return 1 ;;
    esac
}

config_mode() {
    jq -r '.defaultMode // empty' "$1" 2>/dev/null | tr '[:upper:]' '[:lower:]'
}

# Same resolution order as the plugin's caveman-config.js: env var, repo
# config walking up from the session cwd, user config, then "full".
default_mode() {
    env_mode=$(echo "${CAVEMAN_DEFAULT_MODE:-}" | tr '[:upper:]' '[:lower:]')
    if valid_mode "$env_mode"; then
        echo "$env_mode"
        return
    fi

    dir=$(echo "$input" | jq -r '.cwd // empty')
    while [ -n "$dir" ] && [ "$dir" != "/" ]; do
        for candidate in "$dir/.caveman/config.json" "$dir/.caveman.json"; do
            if [ -f "$candidate" ] && [ ! -L "$candidate" ]; then
                repo_mode=$(config_mode "$candidate")
                if valid_mode "$repo_mode"; then
                    echo "$repo_mode"
                    return
                fi
            fi
        done
        dir=$(dirname "$dir")
    done

    user_mode=$(config_mode "${XDG_CONFIG_HOME:-$HOME/.config}/caveman/config.json")
    if valid_mode "$user_mode"; then
        echo "$user_mode"
        return
    fi

    echo "full"
}

write_flag() {
    printf '%s' "$1" > "$session_flag"
}

if [ "$event" = "SessionStart" ]; then
    # Resumed sessions keep the level they had. New sessions start at default.
    if [ ! -f "$session_flag" ]; then
        write_flag "$(default_mode)"
    fi

    find "$flag_dir" -maxdepth 1 -name '.caveman-session-*' \
        -mtime +"$STALE_FLAG_DAYS" -delete 2>/dev/null
    exit 0
fi

[ "$event" = "UserPromptSubmit" ] || exit 0

prompt=$(echo "$input" | jq -r '.prompt // empty' | tr '[:upper:]' '[:lower:]')
[ -n "$prompt" ] || exit 0

# Natural-language activation, same patterns the plugin tracker recognizes.
if echo "$prompt" | grep -qiE '\b(activate|enable|turn on|start|talk like)\b.*\bcaveman\b|\bcaveman\b.*\b(mode|activate|enable|turn on|start)\b|\b(less tokens|fewer tokens|be brief|be terse|shorter answers)\b'; then
    if ! echo "$prompt" | grep -qiE '\b(stop|disable|turn off|deactivate)\b'; then
        write_flag "$(default_mode)"
    fi
fi

first_word=${prompt%%[[:space:]]*}
arg=$(echo "$prompt" | awk '{print $2}')

case "$first_word" in
    /caveman-commit)
        write_flag "commit"
        exit 0 ;;
    /caveman-review)
        write_flag "review"
        exit 0 ;;
    /caveman-compress|/caveman:caveman-compress)
        write_flag "compress"
        exit 0 ;;
    /caveman|/caveman:caveman)
        if [ -z "$arg" ]; then
            write_flag "$(default_mode)"
        else
            case "$arg" in
                off|stop|disable) write_flag "off" ;;
                wenyan-full) write_flag "wenyan" ;;
                # commit/review/compress have their own slash commands.
                commit|review|compress) ;;
                *) valid_mode "$arg" && write_flag "$arg" ;;
            esac
        fi
        exit 0 ;;
esac

# Natural-language deactivation. Write "off" instead of deleting the file so
# the statusline does not fall back to a stale global flag.
if echo "$prompt" | grep -qiE '\b(stop|disable|deactivate|turn off)\b.*\bcaveman\b|\bcaveman\b.*\b(stop|disable|deactivate|turn off)\b|\bnormal mode\b'; then
    write_flag "off"
fi

exit 0
