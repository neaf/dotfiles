#!/usr/bin/env zsh
# Jellyfin server app with libraries on ~/Data/Media (settings seeded on first install only)
source "$DOTFILES_ROOT/lib/common.sh"
load_brew
dir="${0:A:h}"
data="$HOME/Library/Application Support/jellyfin"
run_module 15-data-dirs

ensure_cask jellyfin Jellyfin

# The server rewrites its own files and holds the user database, so config is copied once into
# a data folder that does not exist yet. An existing install is left alone.
if [[ ! -d "$data" ]]; then
  mkdir -p "$data"
  cp -R "$dir/seed/." "$data/"
  find "$data/root" -type f \( -name '*.xml' -o -name '*.mblink' \) -exec sed -i '' "s#__HOME__#$HOME#g" {} +
  log "jellyfin seeded, open Jellyfin and create the admin user at http://localhost:8096"
fi

# Start at login through a launch agent, rewritten and reloaded only when its content changes.
label=com.dotfiles.jellyfin
plist="$HOME/Library/LaunchAgents/$label.plist"
want="$(sed "s#__DIR__#$dir#g" "$dir/$label.plist.template")"
if [[ ! -f "$plist" || "$(<"$plist")" != "$want" ]] || ! launchctl print "gui/$UID/$label" >/dev/null 2>&1; then
  mkdir -p "${plist:h}"
  print -r -- "$want" > "$plist"
  launchctl bootout "gui/$UID" "$plist" 2>/dev/null || true
  launchctl bootstrap "gui/$UID" "$plist"
  log "jellyfin login agent loaded"
fi
