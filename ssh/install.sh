#!/usr/bin/env bash

# Installs the shared SSH config and private host entries from the ssh_config repo.
# Files are copied, not symlinked: ssh rejects configs writable by others (777 on WSL /mnt drives,
# shared storage on Android). Safe to run again after `git pull` in either repo.

set -e

DIR=$(realpath "$(dirname "$0")")
SSH_DIR="$HOME/.ssh"

mkdir -p "$SSH_DIR/config.d"
chmod 700 "$SSH_DIR" "$SSH_DIR/config.d"

# keep the pre-dotfiles config once
if [ -f "$SSH_DIR/config" ] && [ ! -f "$SSH_DIR/config.bak" ]; then
    cp -p "$SSH_DIR/config" "$SSH_DIR/config.bak"
    echo "previous ssh config saved as $SSH_DIR/config.bak"
fi
rm -f "$SSH_DIR/config"
install -m 600 "$DIR/config" "$SSH_DIR/config"
echo "ssh config installed"

# host entries: same lookup order as REPOS_PATH in .aliases.zsh
for dir in "$HOME/repos" /mnt/e/repos /mnt/e/gitdir "$HOME/gitdir" "$HOME/gdir"; do
    if [ -d "$dir/ssh_config" ]; then
        for conf in "$dir"/ssh_config/*.conf; do
            [ -e "$conf" ] || continue
            install -m 600 "$conf" "$SSH_DIR/config.d/"
            echo "ssh host entries installed: $(basename "$conf")"
        done
        exit 0
    fi
done
echo "⚠️ ssh_config repo not found, skipping host entries"
