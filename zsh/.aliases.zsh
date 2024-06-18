# zshrc config
alias reload="source $HOME/.zshrc"
alias zshconfig="vim $HOME/.zshrc"

# starship config
alias shipcfg="vim $HOME/starship.toml"

# Config aliases
alias aliases="vim $HOME/.aliases.zsh"

# cat alternative
alias cat='bat'
alias pcat='bat --style=plain'

# ls alternative
alias ls='lsd -l'
alias lsa='lsd -la'

# DNS tool - dog
alias dns='dog'

# jump back n directories at a time
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

# jump to work directory
alias gdir='cd /mnt/e/gitdir'

# weather
alias wroclaw='curl wttr.in/wroclaw'
alias przemysl='curl wttr.in/przemysl'
alias krakow='curl wttr.in/krakow'
