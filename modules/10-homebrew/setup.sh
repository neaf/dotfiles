#!/usr/bin/env zsh
# Homebrew itself
source "$DOTFILES_ROOT/lib/common.sh"
load_brew
if command -v brew >/dev/null; then
  log "homebrew present"
  exit 0
fi
log "installing homebrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
