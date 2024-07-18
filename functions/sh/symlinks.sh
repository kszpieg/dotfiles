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