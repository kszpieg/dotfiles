export ZSH=$HOME/.oh-my-zsh

# Prompt comes from starship (bottom of this file)
ZSH_THEME=""

# Order matters: fzf-tab before zsh-autosuggestions, zsh-syntax-highlighting last
plugins=(
    docker
    docker-compose
    git
    fzf-tab
    ssh-agent
    sudo
    terraform
    uv
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# Plugin settings must be set before oh-my-zsh is sourced
zstyle :omz:plugins:ssh-agent lazy yes
zstyle :omz:plugins:ssh-agent quiet yes
zstyle :omz:plugins:ssh-agent lifetime 12h

source $ZSH/oh-my-zsh.sh

source $HOME/.aliases.zsh

export PATH=$PATH:$HOME/.local/bin

setopt CORRECT

# Homebrew (Linux)
if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

(( $+commands[zoxide] )) && eval "$(zoxide init --cmd cd zsh)"
(( $+commands[starship] )) && eval "$(starship init zsh)"
