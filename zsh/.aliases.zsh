# zshrc config
alias reload="source $HOME/.zshrc"
alias zshconfig="vim $HOME/.zshrc"

# starship config
alias shipcfg="vim $HOME/.config/starship.toml"

# Config aliases
alias aliases="vim $HOME/.aliases.zsh"

# debian based aliases
alias i="sudo apt install"
alias u="sudo apt update"
alias uu="sudo apt upgrade"
alias r="sudo apt remove"

# cat alternative
alias cat='bat'
alias pcat='bat --style=plain'

# ls alternative
alias ls='lsd --group-directories-first'
alias lsl='lsd --group-directories-first -lh'
alias lsa='lsd --group-directories-first -lhA'

# DNS tool - dog
alias dns='doggo'

# jump back n directories at a time
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

# python stuff
alias python='python3'

# jump to work directory
alias gdir='cd /mnt/e/gitdir'

# git aliases
# update submodule recursively to latest remote commit
alias gsur='gsu --remote --recursive'

# jump to dotfiles
alias dotfiles='cd /mnt/e/gitdir/dotfiles'

# weather
alias wroclaw='curl wttr.in/wroclaw'
alias przemysl='curl wttr.in/przemysl'
alias krakow='curl wttr.in/krakow'
