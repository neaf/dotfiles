#!/usr/bin/env zsh
# Window halves, maximize and display moves
source "$DOTFILES_ROOT/lib/common.sh"
run_module 32-hammerspoon

hs_feature "${0:A:h}/windows.lua"
