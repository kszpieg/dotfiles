#!/usr/bin/env bash

source "$(dirname "$0")/functions/sh/symlinks.sh"

create_ln bash/.bashrc -nf
create_ln zsh/.zshrc -nf
create_ln zsh/.aliases.zsh -nf
create_ln git/.gitconfig -nf # (for work it's different)
create_ln vim/.vimrc -nf
create_ln .config/fastfetch/config.jsonc
create_ln .config/starship.toml
create_ln .config/ghostty/config

