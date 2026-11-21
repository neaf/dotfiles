#!/usr/bin/env zsh
# Karabiner-Elements with the keyboard rules (Caps to Esc/Ctrl, hyper key, shift parentheses)
source "$DOTFILES_ROOT/lib/common.sh"
load_brew

ensure_cask karabiner-elements Karabiner-Elements
ensure_symlink "${0:A:h}/karabiner.json" "$HOME/.config/karabiner/karabiner.json"

warn "Karabiner needs Input Monitoring and its driver approved in System Settings > Privacy & Security"
