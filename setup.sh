#!/usr/bin/env bash

source "$(dirname "$0")/functions/sh/symlinks.sh"

# === Base setup section ===
echo "=====setting up your computer... please wait...====="

if [ "$OSTYPE" = "linux-gnu" ]; then
    DISTRO_TYPE=$(lsb_release -is)
    echo "=====setup for $DISTRO_TYPE====="
elif [ "$OSTYPE" = "darwin" ]; then
    echo "=====setup for MacOS====="
fi

if [ "$OSTYPE" = "linux-gnu" ]; then
    if [ "$DISTRO_TYPE" = "Debian" ] || [ "$DISTRO_TYPE" = "Ubuntu" ]; then
        # run latest updates
        echo "=====checking for updates... please wait...====="
        sudo apt update -y && sudo apt upgrade -y

        # check for curl and install if it's not found
        echo "=====checking for curl...====="
        if test ! "$(which curl)"; then
            sudo apt install curl -y
        fi
        echo DONE
    fi
elif [ "$OSTYPE" = "darwin" ]; then
    # run latest updates
    echo "=====checking for updates... please wait...====="
    sudo softwareupdate -i -a
fi

# check for homebrew and install if it's not found
echo "=====checking for homebrew...====="
if test ! "$(which brew)"; then
    if [ "$OSTYPE" = "linux-gnu" ]; then
        if [ "$DISTRO_TYPE" = "Debian" ] || [ "$DISTRO_TYPE" = "Ubuntu" ]; then
            # install brew dependencies
            echo "=====installing brew dependencies... please wait...====="
            sudo apt install build-essential -y
        fi
    fi
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" < /dev/null
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
else
    echo "===homebrew is installed already==="
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
    if [ "$DISTRO_TYPE" = "Debian" ] || [ "$DISTRO_TYPE" = "Ubuntu" ]; then
        # check for zsh and install if it's not found
        echo "=====checking for zsh...====="
        if test ! "$(which zsh)"; then
            sudo apt install zsh -y
        else
            echo "===zsh is installed already==="
        fi
        echo DONE

        # === App section
        echo "=====installing linux apps...====="

        # install vim, batcat, fzf and htop
        sudo apt install vim bat fzf htop -y
    fi

    # prepare ./local/bin/bat according to documentation of bat
    mkdir -p ~/.local/bin
    ln -s /usr/bin/batcat ~/.local/bin/bat
fi

# check for oh-my-zsh and install if it's not found
echo "=====checking for oh-my-zsh...====="
if test ! "$(which omz)"; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    # clone missing oh-my-zsh plugins
    ZSH_AUTOSUGGESTIONS_PATH="$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    ZSH_SYNTAX_HIGHLIGHTING_PATH="$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    if [ ! -d "$ZSH_AUTOSUGGESTIONS_PATH" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTOSUGGESTIONS_PATH"
    fi
    if [ ! -d "$ZSH_SYNTAX_HIGHLIGHTING_PATH" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_SYNTAX_HIGHLIGHTING_PATH"
    fi
else
    echo "===oh-my-zsh is installed already==="
fi
echo DONE

# check for starship and install if it's not found
echo "=====checking for starship...====="
if test ! "$(which starship)"; then
    sh -c "$(curl -sS https://starship.rs/install.sh)" -y -f
else
    echo "===starfish is installed already==="
fi
echo DONE

# === Symlinks section ===
echo "=====creating symlinks...====="

# remove .zshrc from $HOME (if it exists)
rm -rf "$HOME/.zshrc"

# create symlinks for all configs
source "$(dirname "$0")/configs.sh"

# === Finish section ===

echo "=====almost done... need to reboot====="
sudo reboot
