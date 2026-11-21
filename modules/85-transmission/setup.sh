#!/usr/bin/env zsh
# Transmission BitTorrent client, downloading to ~/Data/Media/Downloads
source "$DOTFILES_ROOT/lib/common.sh"
load_brew
run_module 15-data-dirs

ensure_cask transmission Transmission

target="$HOME/Data/Media/Downloads"
if [[ "$(defaults read org.m0k.transmission DownloadFolder 2>/dev/null)" != "$target" ]]; then
  # A running Transmission rewrites its preferences on quit and would undo this.
  pgrep -x Transmission >/dev/null && die "quit Transmission and rerun"
  defaults write org.m0k.transmission DownloadChoice -string Constant
  defaults write org.m0k.transmission DownloadFolder -string "$target"
  log "transmission downloads to $target"
fi
