#!/usr/bin/env bash
# One-off migration of the repos directory (gitdir -> repos), WSL side.
# Normally called by migrate_repos.ps1, which renames the directory on the Windows side.
# Plan: ai_agents/project_logs/migracja_gitdir_repos.md
#
# usage: migrate_repos.sh check|apply|leftovers --old <path> --new <path> [options]
#   check      read-only: blockers before the rename + preview of what apply would change
#   apply      after the rename: symlinks, Claude Code state, zoxide, then a verification report
#   leftovers  read-only: what still points to <old> (run before removing the junction)
# options:
#   --dry-run         apply: print the actions without doing them
#   --home-link       apply: create ~/<basename of new> -> <new>
#   --drop-home-link  apply: remove ~/<basename of old> if it is a symlink (rollback)

set -uo pipefail

MODE=${1:-}
shift || true
OLD=
NEW=
DRY=false
HOME_LINK=false
DROP_HOME_LINK=false
while [ $# -gt 0 ]; do
    case $1 in
        --old) OLD=${2%/}; shift ;;
        --new) NEW=${2%/}; shift ;;
        --dry-run) DRY=true ;;
        --home-link) HOME_LINK=true ;;
        --drop-home-link) DROP_HOME_LINK=true ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done

case $MODE in
    check|apply|leftovers) ;;
    *) sed -n '2,15p' "$0"; exit 2 ;;
esac
if [ -z "$OLD" ] || [ -z "$NEW" ]; then
    echo "--old and --new are required" >&2
    exit 2
fi

# non-interactive WSL sessions don't have brew (zoxide) in PATH
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

ERRORS=0
section() { echo; echo "== $*"; }
info() { echo "  $*"; }
warn() { echo "  WARN: $*"; }
fail() { echo "  ERROR: $*"; ERRORS=$((ERRORS + 1)); }
run() {
    if $DRY; then
        echo "  [dry-run] $*"
    else
        "$@"
    fi
}

# Claude Code names project dirs after the path with every non-alphanumeric char replaced by '-'
claude_key() { printf '%s' "$1" | sed 's/[^a-zA-Z0-9]/-/g'; }

under_old() {
    case $1 in
        "$OLD" | "$OLD"/*) return 0 ;;
    esac
    return 1
}

list_repos() {
    find "$1" -maxdepth 3 -name node_modules -prune -o -name .git -print -prune 2>/dev/null |
        while IFS= read -r g; do dirname "$g"; done
}

claude_running() {
    pgrep -x claude >/dev/null || pgrep -f 'claude-code/cli' >/dev/null
}

# rewrites path strings in a JSON file (keys and values) or plain text files
PY_REWRITE=$(
    cat <<'EOF'
import json, re, sys
mode, old, new, *files = sys.argv[1:]
word = re.compile(re.escape(old) + r"(?![\w-]|\.\w)")
changed = 0

def fix(s):
    global changed
    if s == old or s.startswith(old + "/"):
        changed += 1
        return new + s[len(old):]
    return s

def walk(o):
    if isinstance(o, dict):
        out = {k: walk(v) for k, v in o.items() if fix(k) == k}
        for k, v in o.items():
            fk = fix(k)
            if fk != k:
                if fk in out:
                    print(f"  WARN: {fk} already existed, replaced by the entry from {k}")
                out[fk] = walk(v)
        return out
    if isinstance(o, list):
        return [walk(v) for v in o]
    if isinstance(o, str):
        return fix(o)
    return o

for path in files:
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    if mode.startswith("json"):
        result = json.dumps(walk(json.loads(text)), indent=2, ensure_ascii=False) + "\n"
    else:
        changed += len(word.findall(text))
        result = word.sub(new, text)
    if mode.endswith("-write"):
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(result)
print(changed)
EOF
)

backup() {
    [ -f "$1" ] && [ ! -e "$1.pre-repos" ] && run cp -p "$1" "$1.pre-repos"
    return 0
}

# --- checks ---------------------------------------------------------------

check_paths() {
    section "paths"
    info "old: $OLD"
    info "new: $NEW"
    if [ "$MODE" = check ]; then
        [ -d "$OLD" ] || fail "$OLD does not exist"
        [ -e "$NEW" ] && fail "$NEW already exists"
    else
        [ -d "$NEW" ] || fail "$NEW does not exist (rename not done?)"
        if [ -e "$OLD" ] && [ "$(realpath "$OLD")" != "$(realpath "$NEW")" ]; then
            fail "$OLD is still a separate directory"
        fi
    fi
}

check_claude() {
    section "Claude Code"
    if claude_running; then
        fail "Claude Code is running; close every session (it rewrites ~/.claude.json on exit)"
    else
        info "not running"
    fi
}

check_repos() {
    section "repos under $OLD"
    local repo n=0
    while IFS= read -r repo; do
        n=$((n + 1))
        if [ -n "$(git -C "$repo" status --porcelain 2>/dev/null)" ]; then
            warn "uncommitted changes: $repo"
        elif git -C "$repo" rev-parse '@{u}' >/dev/null 2>&1 &&
            [ "$(git -C "$repo" rev-list --count '@{u}..HEAD')" -gt 0 ]; then
            warn "unpushed commits: $repo"
        fi
    done < <(list_repos "$OLD")
    info "$n repos checked (the rename itself doesn't touch their content)"
}

check_includeif() {
    section "git includeIf"
    local key pattern want found=false
    local keys
    keys=$(git config --global --get-regexp '^includeif\.' 2>/dev/null | cut -d' ' -f1)
    while IFS= read -r key; do
        [ -n "$key" ] || continue
        pattern=${key#includeif.}
        pattern=${pattern%.path}
        case $pattern in
            gitdir:"$OLD"/* | gitdir/i:"$OLD"/*) ;;
            *) continue ;;
        esac
        found=true
        want=${pattern/"$OLD"/"$NEW"}
        if printf '%s\n' "$keys" | grep -qxF "includeif.$want.path"; then
            info "ok: $want"
        else
            fail "missing [includeIf \"$want\"] next to \"$pattern\" (phase 1); commits there would get the wrong email"
        fi
    done <<<"$keys"
    $found || info "no includeIf under $OLD"
}

check_aliases() {
    section "shell aliases"
    local f
    for f in "$HOME/.aliases.zsh" "$HOME/.bashrc"; do
        [ -f "$f" ] || continue
        if grep -qF "$OLD" "$f" && ! grep -qF "$NEW" "$f"; then
            warn "$f knows $OLD but not $NEW (phase 1 not pulled?)"
        fi
    done
    info "done"
}

# --- changes (apply, previewed by check) ----------------------------------

home_link() {
    section "home link"
    if $DROP_HOME_LINK; then
        local old_link="$HOME/$(basename "$OLD")"
        if [ -L "$old_link" ]; then
            run rm "$old_link"
            info "removed $old_link"
        fi
    fi
    $HOME_LINK || { info "skipped"; return; }
    local link="$HOME/$(basename "$NEW")"
    if [ -L "$link" ] || [ ! -e "$link" ]; then
        run ln -sfn "$NEW" "$link"
        info "$link -> $NEW"
    else
        warn "$link exists and is not a symlink, left alone"
    fi
}

relink_symlinks() {
    section "symlinks in ~ pointing into $OLD"
    local link target n=0
    while IFS= read -r -d '' link; do
        target=$(readlink "$link")
        under_old "$target" || continue
        n=$((n + 1))
        run ln -sfn "$NEW${target#"$OLD"}" "$link"
        info "$link -> $NEW${target#"$OLD"}"
    done < <(find "$HOME" -maxdepth 3 -type l -print0 2>/dev/null)
    info "$n symlinks"
}

move_claude_projects() {
    section "Claude Code project dirs (memory, session history)"
    local dir="$HOME/.claude/projects" old_key new_key p name n=0
    [ -d "$dir" ] || { info "no $dir"; return; }
    old_key=$(claude_key "$OLD")
    new_key=$(claude_key "$NEW")
    for p in "$dir/$old_key" "$dir/$old_key"-*; do
        [ -d "$p" ] || continue
        name=$new_key${p#"$dir/$old_key"}
        if [ -e "$dir/$name" ]; then
            warn "$dir/$name already exists, merge $(basename "$p") into it by hand"
            continue
        fi
        n=$((n + 1))
        run mv "$p" "$dir/$name"
        info "$(basename "$p") -> $name"
    done
    info "$n dirs"
}

rewrite_claude_config() {
    section "Claude Code config files"
    command -v python3 >/dev/null || { fail "python3 not found, fix ~/.claude.json by hand"; return; }
    local suffix=-write
    $DRY && suffix=
    local f="$HOME/.claude.json"
    if [ -f "$f" ]; then
        $DRY || backup "$f"
        info "$f: $(python3 -c "$PY_REWRITE" "json$suffix" "$OLD" "$NEW" "$f") paths"
    fi
    local texts=()
    for f in "$HOME/.claude/settings.json" "$HOME/.claude/CLAUDE.md"; do
        [ -f "$f" ] && texts+=("$f")
    done
    # memory files, from wherever move_claude_projects left them
    local mem
    for mem in "$HOME/.claude/projects/$(claude_key "$NEW")"*/memory/*.md \
        "$HOME/.claude/projects/$(claude_key "$OLD")"*/memory/*.md; do
        [ -f "$mem" ] && texts+=("$mem")
    done
    [ ${#texts[@]} -gt 0 ] || return
    $DRY || backup "$HOME/.claude/settings.json"
    info "settings.json, CLAUDE.md, memory/*.md (${#texts[@]} files):" \
        "$(python3 -c "$PY_REWRITE" "text$suffix" "$OLD" "$NEW" "${texts[@]}") occurrences"
}

fix_zoxide() {
    section "zoxide"
    command -v zoxide >/dev/null || { info "not installed"; return; }
    local entries p n=0
    mapfile -t entries < <(zoxide query -l 2>/dev/null)
    for p in "${entries[@]}"; do
        under_old "$p" || continue
        n=$((n + 1))
        run zoxide remove "$p"
        [ -d "$NEW${p#"$OLD"}" ] && run zoxide add "$NEW${p#"$OLD"}"
    done
    info "$n entries moved (scores reset)"
}

# --- reports --------------------------------------------------------------

report_leftovers() {
    section "still pointing to $OLD"
    local link n=0
    while IFS= read -r -d '' link; do
        under_old "$(readlink "$link")" || continue
        n=$((n + 1))
        warn "symlink $link -> $(readlink "$link")"
    done < <(find "$HOME" -maxdepth 3 -type l -print0 2>/dev/null)
    local p
    for p in "$HOME/.claude/projects/$(claude_key "$OLD")" "$HOME/.claude/projects/$(claude_key "$OLD")"-*; do
        [ -d "$p" ] && { n=$((n + 1)); warn "Claude Code dir $p"; }
    done
    if [ -f "$HOME/.claude.json" ] && grep -qF "\"$OLD" "$HOME/.claude.json"; then
        n=$((n + 1))
        warn "~/.claude.json still has paths under $OLD"
    fi
    if git config --global --get-regexp '^includeif\.' 2>/dev/null | grep -qF "gitdir:$OLD/"; then
        info "includeIf for $OLD still in .gitconfig (remove it in phase 5)"
    fi
    info "$n leftovers"
    [ "$n" -eq 0 ] || ERRORS=$((ERRORS + 1))
}

report_identities() {
    section "git identity per repo (check work repos)"
    local repo
    while IFS= read -r repo; do
        printf '  %-40s %s\n' "$(git -C "$repo" config user.email 2>/dev/null || echo '?')" "${repo#"$NEW"/}"
    done < <(list_repos "$NEW")
}

# --- main -----------------------------------------------------------------

case $MODE in
    check)
        check_paths
        check_claude
        check_includeif
        check_aliases
        check_repos
        echo
        echo "== preview of apply"
        DRY=true
        home_link
        relink_symlinks
        move_claude_projects
        rewrite_claude_config
        fix_zoxide
        ;;
    apply)
        check_paths
        check_claude
        if [ "$ERRORS" -gt 0 ]; then
            echo
            echo "blocked by $ERRORS error(s), nothing changed"
            exit 1
        fi
        home_link
        relink_symlinks
        move_claude_projects
        rewrite_claude_config
        fix_zoxide
        $DRY || { report_leftovers; report_identities; }
        ;;
    leftovers)
        report_leftovers
        ;;
esac

echo
if [ "$ERRORS" -gt 0 ]; then
    echo "$ERRORS error(s)"
    exit 1
fi
echo "ok"
