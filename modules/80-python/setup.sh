#!/usr/bin/env zsh
# Python through uv: uv itself plus the latest managed Python
source "$DOTFILES_ROOT/lib/common.sh"
load_brew

ensure_formula uv
# No-op when the latest minor version is already installed.
uv python install
