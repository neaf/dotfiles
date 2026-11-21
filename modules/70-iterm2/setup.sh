#!/usr/bin/env zsh
# iTerm2 prefs loaded from this folder, JetBrains Mono font, JetBrains Mono and Fish profiles
source "$DOTFILES_ROOT/lib/common.sh"
load_brew
dir="${0:A:h}"

ensure_cask iterm2 iTerm2
ensure_cask font-jetbrains-mono
for profile in jetbrains-mono fish; do
  ensure_symlink "$dir/$profile.json" \
    "$HOME/Library/Application Support/iTerm2/DynamicProfiles/$profile.json"
done

# iTerm2 reads and writes com.googlecode.iterm2.plist in this folder. Takes effect on next launch.
if [[ "$(defaults read com.googlecode.iterm2 PrefsCustomFolder 2>/dev/null)" != "$dir" ]]; then
  defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$dir"
  defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
  log "iTerm2 prefs folder set, restart iTerm2"
fi
