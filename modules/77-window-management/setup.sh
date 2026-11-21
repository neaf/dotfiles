#!/usr/bin/env zsh
# Window halves, maximize and display moves on the hyper key (needs Hammerspoon)
source "$DOTFILES_ROOT/lib/common.sh"
run_module 74-hammerspoon

ensure_symlink "${0:A:h}/windows.lua" "$HOME/.hammerspoon/windows.lua"
