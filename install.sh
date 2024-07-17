#!/usr/bin/env bash

DIR=$(realpath "$(dirname "$0")")

function create_ln() {
    FILE=$(basename "$1")
    PATH_TO_CHECK=$(dirname "$1")

    if [ "$2" = "-nf" ]; then
        echo -ne "creating symlink of $FILE to $HOME/$FILE  "
        ln -sfn "$DIR/$1" "$HOME/$FILE"
        echo DONE
    else
        echo -ne "creating symlink of $1 to $HOME/$1  "
        if [ ! -d "$HOME/$PATH_TO_CHECK" ]; then
            echo "$PATH_TO_CHECK" not exists, creating...
            mkdir -p "$HOME/$PATH_TO_CHECK"
        fi
        ln -sfn "$DIR/$1" "$HOME/$1"
        echo DONE
    fi
}

# === Base setup section ===
echo "=====setting up your computer... please wait...====="

if [ "$OSTYPE" = "linux-gnu" ]; then
    # run latest updates
    echo "=====checking for updates... please wait...====="
    sudo apt update -y && sudo apt upgrade -y

    # check for curl and install if it's not found
    echo "=====checking for curl...====="
    if test ! "$(which curl)"; then
        sudo apt install curl -y
    fi
    echo DONE
elif [ "$OSTYPE" = "darwin" ]; then
    # run latest updates
    echo "=====checking for updates... please wait...====="
    sudo softwareupdate -i -a
fi

# check for homebrew and install if it's not found
echo "=====checking for homebrew...====="
if test ! "$(which brew)"; then
    if [ "$OSTYPE" = "linux-gnu" ]; then
    # install brew dependencies
    echo "=====installing brew dependencies... please wait...====="
    sudo apt install build-essential -y
    fi
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" < /dev/null
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
echo DONE

# === Homebrew section ===
echo "=====installing brew packages...====="

# update homebrew recipes
brew update

# install brew dependencies with bundle
brew tap homebrew/bundle
brew bundle --file ./Brewfile

if [ "$OSTYPE" = "linux-gnu" ]; then
    # check for zsh and install if it's not found
    echo "=====checking for zsh...====="
    if test ! "$(which zsh)"; then
        sudo apt install zsh -y
    fi
    echo DONE

    # === App section
    echo "=====installing linux apps...====="

    # install vim, batcat and htop
    sudo apt install vim bat htop -y

    # prepare ./local/bin/bat according to documentation of bat
    mkdir -p ~/.local/bin
    ln -s /usr/bin/batcat ~/.local/bin/bat
fi

# check for oh-my-zsh and install if it's not found
echo "=====checking for oh-my-zsh...====="
if test ! "$(which omz)"; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    # clone missing oh-my-zsh plugins
    ZSH_AUTOSUGGESTIONS_PATH="$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    ZSH_SYNTAX_HIGHLIGHTING_PATH="$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    if [ ! -d "$ZSH_AUTOSUGGESTIONS_PATH" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTOSUGGESTIONS_PATH"
    fi
    if [ ! -d "$ZSH_SYNTAX_HIGHLIGHTING_PATH" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_SYNTAX_HIGHLIGHTING_PATH"
    fi
fi
echo DONE

# check for starship and install if it's not found
echo "=====checking for starship...====="
if test ! "$(which starship)"; then
    curl -sS https://starship.rs/install.sh | sh
fi
echo DONE

# === Symlinks section ===
echo "=====creating symlinks...====="

# remove .zshrc from $HOME (if it exists)
rm -rf "$HOME/.zshrc"

# create symlinks for all configs
create_ln zsh/.zshrc -nf
create_ln zsh/.aliases.zsh -nf
create_ln git/.gitconfig -nf
create_ln vim/.vimrc -nf
create_ln .config/fastfetch/config.jsonc
create_ln .config/starship.toml

# === Finish section ===

echo "=====almost done...====="

# run zsh for oh-my-zsh loading purposes
zsh

# load zsh config
source "$HOME/.zshrc"

echo "=====your machine is settled up, enjoy!====="
