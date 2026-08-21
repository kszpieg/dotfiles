# zshrc config
alias reload="source $HOME/.zshrc"
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

# suffix aliases
alias -s md="bat"
alias -s json="jless"

# cat alternative
alias cat="bat"
alias pcat="bat --style=plain"

# ls alternative
alias ls="eza --icons --group-directories-first"
alias lsl="eza --icons --group-directories-first -lgh --git"
alias lsa="eza --icons --group-directories-first -lghA --git"
alias lst="eza --icons --group-directories-first -lgh --tree --level 2 --git"
alias lsta="eza --icons --group-directories-first -lghA --tree --level 2 --git"

# DNS tool - dog
alias dns="doggo"

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

# set proper base path for gitdir
if grep -qi microsoft /proc/sys/kernel/osrelease; then
	GITDIR_PATH="/mnt/e/gitdir"
else
	GITDIR_PATH=$HOME
fi

# jump to work directory
alias gdir="cd $GITDIR_PATH"

# git aliases
# update submodule recursively to latest remote commit
alias gsur="gsu --remote --recursive"

# pin spycode's blowfish theme submodule to a specific tag/commit
spypin() {
	local ref="$1"
	local path="$GITDIR_PATH/websites/spycode/themes/blowfish"
	if [[ -z "$ref" ]]; then
		echo "usage: spypin <tag-or-commit>   (pins spycode's blowfish theme submodule)"
		return 1
	fi
	( cd "$path" && git fetch --tags && git checkout "$ref" ) || return 1
	echo "→ blowfish theme now on $ref (detached HEAD)"
	echo "→ don't forget: cd $GITDIR_PATH/websites/spycode && git add themes/blowfish && git commit"
}

# jump to dotfiles
alias dotfiles="cd $GITDIR_PATH/.dotfiles"

# weather
alias wroclaw="curl wttr.in/wroclaw"
alias przemysl="curl wttr.in/przemysl"
alias krakow="curl wttr.in/krakow"
