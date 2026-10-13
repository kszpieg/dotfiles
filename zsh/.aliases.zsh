# zshrc config
# reload shell; with -u also update oh-my-zsh and custom plugins
reload() {
	if [[ "$1" == "-u" ]]; then
		local plugin
		for plugin in "${ZSH_CUSTOM:-$ZSH/custom}"/plugins/*(N/); do
			[[ -d "$plugin/.git" ]] || continue
			echo "=== ${plugin:t} ==="
			git -C "$plugin" pull --ff-only
		done
		echo "=== oh-my-zsh ==="
		zsh -f "$ZSH/tools/upgrade.sh"
	fi
	exec zsh
}
alias zshconfig="vim $HOME/.zshrc"

# starship config
alias shipcfg="vim $HOME/.config/starship.toml"

# config aliases
alias aliases="vim $HOME/.aliases.zsh"

# system update aliases
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "$ID" in
        fedora)
            alias i="sudo dnf install"
            alias u="sudo dnf update"
            alias uu="sudo dnf upgrade"
            alias r="sudo dnf remove"
            ;;
        ubuntu|debian)
            alias i="sudo apt install"
            alias u="sudo apt update"
            alias uu="sudo apt upgrade"
            alias r="sudo apt remove"
            ;;
    esac
fi

# ai tools update
alias aiup='
  echo "=== Codex ===";
  codex update;
  echo;
  echo "=== Copilot ===";
  copilot update;
  echo;
  echo "=== Claude Code ===";
  claude update;
'

# suffix aliases
alias -s md="bat"
if (( $+commands[jless] )); then
    alias -s json="jless"
else
    alias -s json="bat"
fi

# cat alternative
alias cat="bat"
alias pcat="bat --style=plain"

# ls alternative
alias ls="eza --icons --group-directories-first"
alias lsl="eza --icons --group-directories-first -lgh --git"
alias lsa="eza --icons --group-directories-first -lghA --git"
alias lst="eza --icons --group-directories-first -lgh --tree --level 2 --git"
alias lsta="eza --icons --group-directories-first -lghA --tree --level 2 --git"

# DNS tool - doggo, with dig as a fallback on servers
if (( $+commands[doggo] )); then
    alias dns="doggo"
elif (( $+commands[dig] )); then
    alias dns="dig"
fi

# man alternative
alias help="tldr"

# grep alternative
alias grep="rg"

# find alternative
alias find="fd"

# jump back n directories at a time
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."

# clear
alias cl="clear"

# python stuff
alias py="python3"

# set proper base path for gitdir: WSL drive first, then ~/gitdir, ~/gdir and finally $HOME
GITDIR_PATH=$HOME
for dir in /mnt/e/gitdir "$HOME/gitdir" "$HOME/gdir"; do
	if [[ -d "$dir" ]]; then
		GITDIR_PATH="$dir"
		break
	fi
done
unset dir

# jump to work directory
alias gdir="cd $GITDIR_PATH"

# git aliases
# update submodule recursively to latest remote commit
alias gsur="gsu --remote --recursive"

# pin spycode's blowfish theme submodule to a specific tag/commit
spypin() {
	local ref="$1"
	local theme_path="$GITDIR_PATH/websites/spycode/themes/blowfish"
	if [[ -z "$ref" ]]; then
		echo "usage: spypin <tag-or-commit>   (pins spycode's blowfish theme submodule)"
		return 1
	fi
	( cd "$theme_path" && git fetch --tags && git checkout "$ref" ) || return 1
	echo "→ blowfish theme now on $ref (detached HEAD)"
	echo "→ don't forget: cd $GITDIR_PATH/websites/spycode && git add themes/blowfish && git commit"
}

# jump to dotfiles (resolved from the real location of this file)
alias dotfiles="cd ${${(%):-%x}:A:h:h}"

# weather
alias wroclaw="curl wttr.in/wroclaw"
alias przemysl="curl wttr.in/przemysl"
alias krakow="curl wttr.in/krakow"
