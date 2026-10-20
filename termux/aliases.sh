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

# pull dotfiles and ssh_config, then reinstall the ssh config
ssh-sync() {
    git -C "$DOTFILES_PATH" pull --ff-only &&
        git -C "$GITDIR_PATH/ssh_config" pull --ff-only &&
        bash "$DOTFILES_PATH/ssh/install.sh"
}
