#!/bin/bash
# Claude Code status line: model, git branch, context usage, caveman mode.
# Receives session JSON on stdin, prints one line. Needs jq.

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "?"')
context_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0 | floor')
used_tokens=$(echo "$input" | jq -r '((.context_window.total_input_tokens // 0) + (.context_window.total_output_tokens // 0))')
max_tokens=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // "."')

branch=$(git -C "$project_dir" branch --show-current 2>/dev/null)

humanize() {
    awk -v n="$1" 'BEGIN {
        if (n >= 1000000) printf "%.1fM", n / 1000000
        else if (n >= 1000) printf "%dk", n / 1000
        else printf "%d", n
    }'
}

cyan='\033[1;36m'
blue='\033[34m'
dim='\033[2m'
orange='\033[38;5;208m'
red='\033[31m'
yellow='\033[33m'
reset='\033[0m'

# Context number: green under 60%, yellow under 85%, red above.
if [ "$context_pct" -ge 85 ]; then
    pct_color='\033[31m'
elif [ "$context_pct" -ge 60 ]; then
    pct_color='\033[33m'
else
    pct_color='\033[32m'
fi

# Rate-limit usage only arrives on Pro/Max subscription sessions.
five_hour_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty | floor')
seven_day_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty | floor')
five_hour_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_day_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# Time until an epoch timestamp, shortest form that still reads: 18m, 4h32m, 3d.
until_reset() {
    diff=$(( $1 - $(date +%s) ))
    if [ "$diff" -le 0 ]; then
        printf 'now'
    elif [ "$diff" -ge 86400 ]; then
        printf '%dd' "$(( diff / 86400 ))"
    elif [ "$diff" -ge 3600 ]; then
        printf '%dh%02dm' "$(( diff / 3600 ))" "$(( diff % 3600 / 60 ))"
    else
        printf '%dm' "$(( diff / 60 ))"
    fi
}

# Dim label, 5-cell bar and percent colored like the ctx number,
# then dim time until the window resets.
usage_segment() {
    seg_pct=$1
    seg_label=$2
    seg_reset=$3

    if [ "$seg_pct" -ge 85 ]; then
        seg_color='\033[31m'
    elif [ "$seg_pct" -ge 60 ]; then
        seg_color='\033[33m'
    else
        seg_color='\033[32m'
    fi

    # One cell per 20%, rounded; any nonzero usage lights at least one cell.
    seg_filled=$(( (seg_pct + 10) / 20 ))
    [ "$seg_filled" -gt 5 ] && seg_filled=5
    [ "$seg_filled" -eq 0 ] && [ "$seg_pct" -gt 0 ] && seg_filled=1

    seg_bar=""
    seg_i=0
    while [ "$seg_i" -lt 5 ]; do
        if [ "$seg_i" -lt "$seg_filled" ]; then
            seg_bar="${seg_bar}▰"
        else
            seg_bar="${seg_bar}▱"
        fi
        seg_i=$(( seg_i + 1 ))
    done

    seg_countdown=""
    if [ -n "$seg_reset" ]; then
        seg_countdown=$(printf ' %b(%s)%b' "$dim" "$(until_reset "$seg_reset")" "$reset")
    fi

    printf '%b%s%b %b%s %s%%%b%s' "$dim" "$seg_label" "$reset" "$seg_color" "$seg_bar" "$seg_pct" "$reset" "$seg_countdown"
}

usage=""
if [ -n "$five_hour_pct" ]; then
    usage=" $(usage_segment "$five_hour_pct" "5h" "$five_hour_reset")"
fi
if [ -n "$seven_day_pct" ]; then
    [ -n "$usage" ] && usage="$usage$(printf ' %b·%b' "$dim" "$reset")"
    usage="$usage $(usage_segment "$seven_day_pct" "7d" "$seven_day_reset")"
fi
if [ -n "$usage" ]; then
    usage=$(printf ' %b|%b%s' "$dim" "$reset" "$usage")
fi

# One short nudge at the end of the line. Most urgent condition wins,
# nothing shows while everything is calm.
advice_segment() {
    printf ' %b|%b %b%s%b' "$dim" "$reset" "$1" "$2" "$reset"
}

advice=""
if [ "$context_pct" -ge 85 ]; then
    advice=$(advice_segment "$red" "⚠ /compact now")
elif [ "${five_hour_pct:-0}" -ge 85 ]; then
    advice=$(advice_segment "$red" "⚠ 5h limit near, pause soon")
elif [ "${seven_day_pct:-0}" -ge 85 ]; then
    advice=$(advice_segment "$red" "⚠ weekly limit near")
elif [ "$context_pct" -ge 70 ]; then
    advice=$(advice_segment "$yellow" "/compact soon, or /clear for new task")
elif [ "${five_hour_pct:-0}" -ge 70 ]; then
    advice=$(advice_segment "$yellow" "5h window filling, batch your asks")
elif [ "${seven_day_pct:-0}" -ge 70 ]; then
    advice=$(advice_segment "$yellow" "weekly window filling")
fi

# Caveman level. The caveman-session-flag.sh hook keeps a per-session flag;
# the plugin's global flag is the fallback for sessions started before the
# hook was installed. Unknown or "off" content means inactive.
caveman_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
session_id=$(echo "$input" | jq -r '.session_id // empty')
level=""
if [ -n "$session_id" ] && [ -f "$caveman_dir/.caveman-session-$session_id" ]; then
    level=$(head -c 64 "$caveman_dir/.caveman-session-$session_id")
elif [ -f "$caveman_dir/.caveman-active" ]; then
    level=$(head -c 64 "$caveman_dir/.caveman-active")
fi

caveman=""
case "$level" in
    lite|full|ultra|wenyan|wenyan-lite|wenyan-full|wenyan-ultra|commit|review|compress)
        caveman=$(printf ' %b|%b %bcaveman:%s%b' "$dim" "$reset" "$orange" "$level" "$reset")
        ;;
esac

printf '%b[%s]%b %b%s%b %b|%b ctx %b%s%%%b %b(%s/%s)%b%s%s%s\n' \
    "$cyan" "$model" "$reset" \
    "$blue" "${branch:-no branch}" "$reset" \
    "$dim" "$reset" \
    "$pct_color" "$context_pct" "$reset" \
    "$dim" "$(humanize "$used_tokens")" "$(humanize "$max_tokens")" "$reset" \
    "$usage" "$caveman" "$advice"
