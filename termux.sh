#!/usr/bin/env bash

# Minimal setup for Termux on Android: SSH client and git only

set -e

case "$OSTYPE" in
    linux-android*) ;;
    *)
        echo "termux.sh is meant for Termux only (found: $OSTYPE)"
        exit 1
        ;;
esac

echo "=====termux: installing openssh and git====="
pkg upgrade -y
pkg install -y openssh git

echo "=====termux: ssh config====="
bash "$(dirname "$0")/ssh/install.sh"
echo DONE
