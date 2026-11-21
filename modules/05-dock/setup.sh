#!/usr/bin/env zsh
# Dock size on every run, and every Apple app removed from the Dock once, on first run.
# Uses only macOS tools, so it works before Homebrew exists.
source "$DOTFILES_ROOT/lib/common.sh"

tilesize=40  # icon size in points, macOS default is 48
if [[ "$(defaults read com.apple.dock tilesize 2>/dev/null)" != "$tilesize" ]]; then
  defaults write com.apple.dock tilesize -int $tilesize
  killall Dock 2>/dev/null
  log "dock icon size set to $tilesize"
fi

marker="$HOME/.local/state/dotfiles/dock-cleaned"
[[ -f "$marker" ]] && { log "dock already cleaned"; exit 0; }

plist="$HOME/Library/Preferences/com.apple.dock.plist"
pb=/usr/libexec/PlistBuddy
[[ -f "$plist" ]] || die "no Dock preferences yet, log in once and rerun"

# Bundle id of each Dock app, by position. An entry without one (a spacer) stays.
ids=()
while $pb -c "Print :persistent-apps:${#ids}" "$plist" >/dev/null 2>&1; do
  ids+=("$($pb -c "Print :persistent-apps:${#ids}:tile-data:bundle-identifier" "$plist" 2>/dev/null)")
done

# Delete from the end so earlier positions stay valid.
removed=0
for (( i = ${#ids}; i >= 1; i-- )); do
  if [[ "${ids[i]}" == com.apple.* ]]; then
    $pb -c "Delete :persistent-apps:$((i - 1))" "$plist"
    (( removed++ ))
  fi
done

killall cfprefsd 2>/dev/null
killall Dock
mkdir -p "${marker:h}"
touch "$marker"
log "removed $removed Apple apps from the Dock"
