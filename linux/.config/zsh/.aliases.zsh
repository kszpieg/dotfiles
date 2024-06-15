# config path
export MY_CFG_PATH=$HOME/.config/

# zshrc config
alias reload="source $MY_CFG_PATH/zsh/.zshrc"
alias zshconfig="vim $MY_CFG_PATH/zsh/.zshrc"

# starship config
alias shipcfg="vim $MY_CFG_PATH/starship.toml"

# Config aliases
alias aliases="vim $MY_CFG_PATH/zsh/.aliases.zsh"

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
