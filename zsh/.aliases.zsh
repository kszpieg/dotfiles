# zshrc config
alias reload="source $HOME/.zshrc"
alias zshconfig="vim $HOME/.zshrc"

# starship config
alias shipcfg="vim $HOME/.config/starship.toml"

# Config aliases
alias aliases="vim $HOME/.aliases.zsh"

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

# cat alternative
alias cat="bat"
alias pcat="bat --style=plain"

# ls alternative
alias ls="eza --icons --group-directories-first"
alias lsl="eza --icons --group-directories-first -lgh"
alias lsa="eza --icons --group-directories-first -lghA"
alias lst="eza --icons --group-directories-first -lgh --tree --level 2"
alias lsta="eza --icons --group-directories-first -lghA --tree --level 2"

# DNS tool - dog
alias dns="doggo"

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

# jump to work directory
alias gdir="cd $HOME/gitdir"

# git aliases
# update submodule recursively to latest remote commit
alias gsur="gsu --remote --recursive"

# jump to dotfiles
alias dotfiles="cd $HOME/gitdir/.dotfiles"

# weather
alias wroclaw="curl wttr.in/wroclaw"
alias przemysl="curl wttr.in/przemysl"
alias krakow="curl wttr.in/krakow"
