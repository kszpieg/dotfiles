#!/usr/bin/env bash

set -e

sudo -v

if [ -f "$(dirname "$0")/functions/sh/symlinks.sh" ]; then
    source "$(dirname "$0")/functions/sh/symlinks.sh"
else
    echo "⚠️ symlinks.sh not found!"
fi

echo "=====setting up your computer... please wait...====="

# === Detect OS and Distribution ===
DISTRO_TYPE=""
case "$OSTYPE" in
    linux-gnu*)
        if [ -f /etc/os-release ]; then
            DISTRO_TYPE=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
            echo "=====setup for Linux: $DISTRO_TYPE====="
        fi
        ;;
    darwin*) 
        DISTRO_TYPE="macos"
        echo "=====setup for MacOS====="
        ;;
    *) 
        echo "Unsupported OS: $OSTYPE"
        exit 1
        ;;
esac

# === Update system & curl ===
echo "=====checking for updates... please wait...====="
case "$DISTRO_TYPE" in
    ubuntu|debian)
        sudo apt update -y && sudo apt upgrade -y
        if ! command -v curl >/dev/null 2>&1; then sudo apt install curl -y; fi
        ;;
    fedora)
        sudo dnf update -y
        if ! command -v curl >/dev/null 2>&1; then sudo dnf install curl -y; fi
        ;;
    macos)
        sudo softwareupdate -i -a
        ;;
esac

# === Homebrew ===
echo "=====checking for homebrew...====="
if ! command -v brew >/dev/null 2>&1; then
    case "$DISTRO_TYPE" in
        ubuntu|debian)
            sudo apt install build-essential -y
            ;;
        fedora)
            sudo dnf group install development-tools
            sudo dnf install procps-ng curl file git -y
            ;;
    esac
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" < /dev/null
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
else
    echo "===homebrew is installed already==="
fi
echo DONE

# === Install Brew Packages ===
echo "=====installing brew packages...====="
# update brew recipes
brew update
if [ -f "./Brewfile" ]; then
    brew bundle --file ./Brewfile
else
    echo "⚠️ Brewfile not found, skipping brew bundle."
fi

# === Linux-only apps ===
if [ "$OSTYPE" = "linux-gnu" ]; then
    # check for zsh and install if it's not found
    echo "=====checking for zsh...====="
    if ! command -v zsh >/dev/null 2>&1; then
        case "$DISTRO_TYPE" in
            ubuntu|debian) sudo apt install zsh -y ;;
            fedora) sudo dnf install zsh -y ;;
        esac
    else
        echo "===zsh is installed already==="
    fi
    echo DONE

    echo "=====installing linux apps...====="
    # install vim, batcat, fzf nmap ripgrep fd-find procs and network tools
    # for ubuntu/debian install bottom and zoxide via homebrew
    # fedora install bottom and zoxide via dnf
    case "$DISTRO_TYPE" in
        ubuntu|debian)
            sudo apt install vim bat fzf net-tools nmap ripgrep fd-find procs -y
            mkdir -p ~/.local/bin
            ln -sf /usr/bin/batcat ~/.local/bin/bat
	    brew install bottom zoxide
            ;;
        fedora)
            sudo dnf copr enable atim/bottom -y
	    sudo dnf install vim bat bottom fzf net-tools nmap ripgrep fd-find procs zoxide -y
	    ;;
    esac
fi


# === Oh My Zsh ===
echo "=====checking for oh-my-zsh...====="
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    # clone missing oh-my-zsh plugins
    FZF_TAB_PATH="$HOME/.oh-my-zsh/custom/plugins/fzf-tab"
    ZSH_AUTOSUGGESTIONS_PATH="$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    ZSH_SYNTAX_HIGHLIGHTING_PATH="$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    if [ ! -d "$FZF_TAB_PATH" ]; then
        git clone https://github.com/Aloxaf/fzf-tab "$FZF_TAB_PATH"
    fi
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

# === Starship ===
echo "=====checking for starship...====="
if ! command -v starship >/dev/null 2>&1; then
    sh -c "$(curl -sS https://starship.rs/install.sh)" -y -f
else
    echo "===starship is installed already==="
fi
echo DONE

# === Symlinks ===
echo "=====creating symlinks...====="
# remove .zshrc from $HOME (if it exists)
rm -rf "$HOME/.zshrc"
if [ -f "$(dirname "$0")/configs.sh" ]; then
    source "$(dirname "$0")/configs.sh"
else
    echo "⚠️ configs.sh not found!"
fi

# === Finish section ===
echo "=====almost done... need to reboot====="
read -p "Reboot now? [y/N]: " REBOOT_CONFIRM
if [[ "$REBOOT_CONFIRM" =~ ^[Yy]$ ]]; then
    sudo reboot
fi
