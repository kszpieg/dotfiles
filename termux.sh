#!/usr/bin/env bash

# Minimal setup for Termux on Android: SSH client, git, eza and aliases

set -e

case "$OSTYPE" in
    linux-android*) ;;
    *)
        echo "termux.sh is meant for Termux only (found: $OSTYPE)"
        exit 1
        ;;
esac

echo "=====termux: installing openssh, git and eza====="
pkg upgrade -y
pkg install -y openssh git eza

echo "=====termux: ssh config====="
bash "$(dirname "$0")/ssh/install.sh"

echo "=====termux: aliases====="
ALIASES_FILE="$(realpath "$(dirname "$0")")/termux/aliases.sh"
touch "$HOME/.bashrc"
if ! grep -qF "$ALIASES_FILE" "$HOME/.bashrc"; then
    echo "[ -f \"$ALIASES_FILE\" ] && source \"$ALIASES_FILE\"" >> "$HOME/.bashrc"
    echo "aliases added to ~/.bashrc, run: source ~/.bashrc"
else
    echo "aliases already in ~/.bashrc"
fi
echo DONE
