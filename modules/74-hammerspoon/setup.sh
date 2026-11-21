#!/usr/bin/env zsh
# Hammerspoon app and init.lua, the host for the display and audio switchers
source "$DOTFILES_ROOT/lib/common.sh"
load_brew

ensure_cask hammerspoon Hammerspoon
ensure_symlink "${0:A:h}/init.lua" "$HOME/.hammerspoon/init.lua"

warn "Hammerspoon needs Accessibility access: System Settings > Privacy & Security > Accessibility"
