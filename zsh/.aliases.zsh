# zshrc config
alias reload="source $HOME/.zshrc"
alias zshconfig="vim $HOME/.zshrc"

# starship config
alias shipcfg="vim $HOME/.config/starship.toml"

# Config aliases
alias aliases="vim $HOME/.aliases.zsh"

# cat alternative
alias cat='bat'
alias pcat='bat --style=plain'

# ls alternative
alias ls='lsd -l'
alias lsa='lsd -lA'

# DNS tool - dog
alias dns='doggo'

# jump back n directories at a time
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

# clear
alias cl='clear'

# python stuff
alias python='python3'

# jump to work directory
alias gdir='cd /mnt/e/gitdir'

# jump to dotfiles
alias dotfiles='cd /mnt/e/gitdir/dotfiles'

# weather
alias wroclaw='curl wttr.in/wroclaw'
alias przemysl='curl wttr.in/przemysl'
alias krakow='curl wttr.in/krakow'
