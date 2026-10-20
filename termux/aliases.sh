# Aliases for Termux (bash); sourced from ~/.bashrc by termux.sh

# dotfiles path from this file's location
DOTFILES_PATH=$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")

# set proper base path for gitdir: ~/gitdir, ~/gdir and finally $HOME (as in .aliases.zsh)
GITDIR_PATH=$HOME
for dir in "$HOME/gitdir" "$HOME/gdir"; do
    if [ -d "$dir" ]; then
        GITDIR_PATH="$dir"
        break
    fi
done
unset dir

alias gdir="cd $GITDIR_PATH"
alias dotfiles="cd $DOTFILES_PATH"

# package aliases (same names as on Ubuntu/Fedora in .aliases.zsh)
alias i="pkg install"
alias u="pkg update"
alias uu="pkg upgrade"
alias r="pkg uninstall"

# ls alternative (no --icons: Termux's default font has no Nerd Font glyphs)
alias ls="eza --group-directories-first"
alias lsl="eza --group-directories-first -lgh --git"
alias lsa="eza --group-directories-first -lghA --git"
alias lst="eza --group-directories-first -lgh --tree --level 2 --git"
alias lsta="eza --group-directories-first -lghA --tree --level 2 --git"

# jump back n directories at a time
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."

# clear
alias cl="clear"

# git aliases: read-only ones from oh-my-zsh's git plugin, same names
# (the phone can't push: ssh_config has a read-only deploy key, dotfiles is cloned over HTTPS)
alias g="git"
alias gst="git status"
alias gss="git status --short"
alias gl="git pull"
alias gf="git fetch"
alias gcl="git clone --recurse-submodules"
alias glog="git log --oneline --decorate --graph"
alias gd="git diff"

# pull dotfiles and ssh_config, then reinstall the ssh config
ssh-sync() {
    git -C "$DOTFILES_PATH" pull --ff-only &&
        git -C "$GITDIR_PATH/ssh_config" pull --ff-only &&
        bash "$DOTFILES_PATH/ssh/install.sh"
}
