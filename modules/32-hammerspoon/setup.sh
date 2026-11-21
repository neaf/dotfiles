#!/usr/bin/env zsh
# Automation host for the hotkey modules
source "$DOTFILES_ROOT/lib/common.sh"
load_brew

ensure_cask hammerspoon Hammerspoon
init_linked=0
[[ -L "$HOME/.hammerspoon/init.lua" && "$(readlink "$HOME/.hammerspoon/init.lua")" == "${0:A:h}/init.lua" ]] && init_linked=1
ensure_symlink "${0:A:h}/init.lua" "$HOME/.hammerspoon/init.lua"
# Start it now, and again when init.lua changed under a running app.
if ! pgrep -x Hammerspoon >/dev/null || (( ! init_linked )); then hs_launch; fi

warn "Hammerspoon needs Accessibility access: System Settings > Privacy & Security > Accessibility"
