#!/usr/bin/env bash
# Claude Code status line: model, repo, context, rate limits (5h/7d) with pace, prompt cache.
# Reads the session JSON from stdin, prints one line, and snapshots rate limits to
# ~/.claude/state/usage.json so agents can read the last known values between sessions.

input=$(cat)
now=$(date +%s)

# One jq pass; empty fields stay empty so every segment can skip itself.
# Unit separator instead of tab: read collapses runs of whitespace delimiters, which would
# shift every field after an empty one.
IFS=$'\x1f' read -r model effort cwd ctx_pct \
    rl5_pct rl5_reset rl7_pct rl7_reset \
    cache_ttl cache_warm cache_exp < <(
    jq -r '[
        .model.display_name // "",
        .effort.level // "",
        .workspace.current_dir // .cwd // "",
        (.context_window.used_percentage // "" | tostring),
        (.rate_limits.five_hour.used_percentage // "" | tostring),
        (.rate_limits.five_hour.resets_at // "" | tostring),
        (.rate_limits.seven_day.used_percentage // "" | tostring),
        (.rate_limits.seven_day.resets_at // "" | tostring),
        .prompt_cache.ttl // "",
        (.prompt_cache.warm // "" | tostring),
        (.prompt_cache.expires_at // "" | tostring)
    ] | join("\u001f")' <<<"$input"
)

RESET=$'\033[0m'
DIM=$'\033[2m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
CYAN=$'\033[36m'
MAGENTA=$'\033[35m'
GRAY=$'\033[90m'
SEP=" ${DIM}│${RESET} "

ICON_MODEL="󰚩"
ICON_DIR=""
ICON_BRANCH=""
ICON_CACHE=""

# Green below 50%, yellow below 80%, red from 80%
color_for() {
    local pct=${1%.*}
    if ((pct >= 80)); then printf '%s' "$RED"
    elif ((pct >= 50)); then printf '%s' "$YELLOW"
    else printf '%s' "$GREEN"
    fi
}

bar() {
    local pct=${1%.*} width=10 filled i out=""
    filled=$(((pct * width + 50) / 100))
    for ((i = 0; i < width; i++)); do
        if ((i < filled)); then out+="▓"; else out+="░"; fi
    done
    printf '%s' "$out"
}

# "1h 12m" or "42m"
duration() {
    local secs=$1 h m
    ((secs < 0)) && secs=0
    h=$((secs / 3600))
    m=$(((secs % 3600) / 60))
    if ((h > 0)); then printf '%dh %02dm' "$h" "$m"; else printf '%dm' "$m"; fi
}

# "pt 09:00" — Polish weekday abbreviation plus time
weekday_time() {
    local days=(pn wt śr czw pt sob nd) dow hm
    read -r dow hm < <(date -d "@$1" '+%u %H:%M')
    printf '%s %s' "${days[dow - 1]}" "$hm"
}

# Arrow when usage runs ahead of elapsed window time by more than 10 points
pace_arrow() {
    local used=${1%.*} reset=$2 window=$3 elapsed_pct
    elapsed_pct=$(((window - (reset - now)) * 100 / window))
    if ((used >= 10 && used > elapsed_pct + 10)); then
        printf ' %s↑%s' "$YELLOW" "$RESET"
    fi
}

segments=()

if [[ -n $model ]]; then
    seg="${CYAN}${ICON_MODEL} ${model}${RESET}"
    [[ -n $effort ]] && seg+=" ${DIM}${effort}${RESET}"
    segments+=("$seg")
fi

if [[ -n $cwd ]]; then
    seg="${ICON_DIR} ${cwd##*/}"
    branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --quiet --short HEAD 2>/dev/null)
    if [[ -n $branch ]]; then
        dirty=""
        if [[ -n $(git -C "$cwd" --no-optional-locks status --porcelain --untracked-files=no 2>/dev/null | head -c1) ]]; then
            dirty="*"
        fi
        seg+="  ${MAGENTA}${ICON_BRANCH} ${branch}${dirty}${RESET}"
    fi
    segments+=("$seg")
fi

if [[ -n $ctx_pct ]]; then
    c=$(color_for "$ctx_pct")
    segments+=("ctx ${c}$(bar "$ctx_pct") ${ctx_pct%.*}%${RESET}")
fi

if [[ -n $rl5_pct && -n $rl5_reset ]]; then
    c=$(color_for "$rl5_pct")
    segments+=("5h ${c}${rl5_pct%.*}%${RESET}$(pace_arrow "$rl5_pct" "$rl5_reset" 18000)  ${DIM}↻ $(duration $((rl5_reset - now)))${RESET}")
fi

if [[ -n $rl7_pct && -n $rl7_reset ]]; then
    c=$(color_for "$rl7_pct")
    segments+=("7d ${c}${rl7_pct%.*}%${RESET}$(pace_arrow "$rl7_pct" "$rl7_reset" 604800)  ${DIM}↻ $(weekday_time "$rl7_reset")${RESET}")
fi

if [[ -n $cache_ttl ]]; then
    if [[ $cache_warm == "true" && -n $cache_exp ]]; then
        segments+=("${ICON_CACHE} ${cache_ttl} ${GREEN}●${RESET} $(duration $((cache_exp - now)))")
    else
        segments+=("${ICON_CACHE} ${cache_ttl} ${GRAY}○ cold${RESET}")
    fi
fi

line=""
for i in "${!segments[@]}"; do
    ((i > 0)) && line+="$SEP"
    line+="${segments[i]}"
done
printf '%s\n' "$line"

# Snapshot for agents; written atomically so a reader never sees a half-written file
if [[ -n $rl5_pct || -n $rl7_pct ]]; then
    state_dir="$HOME/.claude/state"
    if mkdir -p "$state_dir" 2>/dev/null && tmp=$(mktemp "$state_dir/usage.json.XXXXXX" 2>/dev/null) &&
        jq --arg now "$(date -Iseconds)" '{
            updated_at: $now,
            session_id: .session_id,
            five_hour: (.rate_limits.five_hour // null
                | if . then {used_percentage, resets_at: (.resets_at | strflocaltime("%Y-%m-%dT%H:%M:%S%z"))} else null end),
            seven_day: (.rate_limits.seven_day // null
                | if . then {used_percentage, resets_at: (.resets_at | strflocaltime("%Y-%m-%dT%H:%M:%S%z"))} else null end),
            cache_ttl: .prompt_cache.ttl
        }' <<<"$input" >"$tmp" 2>/dev/null; then
        mv "$tmp" "$state_dir/usage.json"
    else
        [[ -n ${tmp:-} ]] && rm -f "$tmp"
    fi
fi
