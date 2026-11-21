#!/usr/bin/env zsh
# 1Password and Brave Browser, needed first for sign-ins
source "$DOTFILES_ROOT/lib/common.sh"
load_brew
ensure_cask 1password 1Password
ensure_cask brave-browser "Brave Browser"
