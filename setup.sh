#!/usr/bin/env bash

set -e

# === Arguments ===
# --server: minimal setup for servers (no Homebrew, no dev tools, no AI tools)
SERVER_MODE=false
for arg in "$@"; do
    case "$arg" in
        --server) SERVER_MODE=true ;;
        *)
            echo "Unknown option: $arg"
            echo "Usage: $0 [--server]"
            exit 1
            ;;
    esac
done

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

if [ "$SERVER_MODE" = true ]; then
    case "$DISTRO_TYPE" in
        ubuntu|debian) echo "=====server mode: minimal setup=====" ;;
        *)
            echo "Server mode supports only Ubuntu/Debian (found: $DISTRO_TYPE)"
            exit 1
            ;;
    esac
fi

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

if [ "$SERVER_MODE" = false ]; then
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
    # install vim, batcat, fzf, ripgrep, fd-find and htop
    # full setup: also nmap and git-lfs (zoxide and the rest come from Brewfile)
    # server setup: also eza, zoxide, jq and dig from apt instead of Brewfile
    case "$DISTRO_TYPE" in
        ubuntu|debian)
            if [ "$SERVER_MODE" = true ]; then
                sudo apt install vim bat fzf ripgrep fd-find htop eza zoxide jq dnsutils -y
            else
                sudo apt install vim bat fzf nmap ripgrep fd-find htop git-lfs -y
            fi
            mkdir -p ~/.local/bin
            ln -sf /usr/bin/batcat ~/.local/bin/bat
            ln -sf "$(which fdfind)" ~/.local/bin/fd
            ;;
        fedora)
            sudo dnf install vim bat fzf nmap ripgrep fd-find htop git-lfs -y
            ;;
    esac

    # install terraform from the HashiCorp repository (on Mac it comes from Brewfile)
    echo "=====checking for terraform...====="
    if [ "$SERVER_MODE" = true ]; then
        echo "===server mode, skipping terraform==="
    elif ! command -v terraform >/dev/null 2>&1; then
        case "$DISTRO_TYPE" in
            ubuntu|debian)
                sudo install -m 0755 -d /etc/apt/keyrings
                sudo curl -fsSL https://apt.releases.hashicorp.com/gpg -o /etc/apt/keyrings/hashicorp.asc
                sudo tee /etc/apt/sources.list.d/hashicorp.sources >/dev/null <<EOF
Types: deb
URIs: https://apt.releases.hashicorp.com
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: main
Signed-By: /etc/apt/keyrings/hashicorp.asc
EOF
                sudo apt update -y && sudo apt install terraform -y
                ;;
            fedora)
                sudo dnf config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
                sudo dnf install terraform -y
                ;;
        esac
    else
        echo "===terraform is installed already==="
    fi
    echo DONE

    # server setup: starship and tlrc as single binaries (on full setup both come from Brewfile)
    if [ "$SERVER_MODE" = true ]; then
        echo "=====checking for starship...====="
        if ! command -v starship >/dev/null 2>&1; then
            curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
        else
            echo "===starship is installed already==="
        fi
        echo DONE

        # tealdeer from apt is too old to download pages, so tlrc comes from its GitHub release
        echo "=====checking for tlrc...====="
        if ! command -v tldr >/dev/null 2>&1; then
            TLRC_VERSION=$(curl -fsSL -o /dev/null -w '%{url_effective}' https://github.com/tldr-pages/tlrc/releases/latest)
            TLRC_VERSION=${TLRC_VERSION##*/}
            TLRC_DEB="tlrc-${TLRC_VERSION}-$(uname -m)-unknown-linux-musl.deb"
            curl -fsSL -o "/tmp/$TLRC_DEB" "https://github.com/tldr-pages/tlrc/releases/download/${TLRC_VERSION}/${TLRC_DEB}"
            sudo apt install "/tmp/$TLRC_DEB" -y
            rm -f "/tmp/$TLRC_DEB"
        else
            echo "===tlrc is installed already==="
        fi
        echo DONE
    fi
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

# === Symlinks ===
echo "=====creating symlinks...====="
# remove .zshrc from $HOME (if it exists)
rm -rf "$HOME/.zshrc"
if [ -f "$(dirname "$0")/configs.sh" ]; then
    source "$(dirname "$0")/configs.sh"
else
    echo "⚠️ configs.sh not found!"
fi

# === Copilot, Claude and Codex ===
if [ "$SERVER_MODE" = false ]; then
    echo "=====installing Copilot, Claude and Codex... ====="
    echo "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
    echo "Done!"
    echo "Installing Copilot CLI..."
    curl -fsSL https://gh.io/copilot-install | bash
    echo "Done!"
    echo "Installing Codex CLI..."
    curl -fsSL https://chatgpt.com/codex/install.sh | sh
    echo "Done!"
fi

# === Finish section ===
echo "=====almost done... need to reboot====="
read -p "Reboot now? [y/N]: " REBOOT_CONFIRM
if [[ "$REBOOT_CONFIRM" =~ ^[Yy]$ ]]; then
    sudo reboot
fi
