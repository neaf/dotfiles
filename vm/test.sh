#!/usr/bin/env zsh
# Boots a fresh macOS VM (Tart) with this repo mounted, to try ./install.sh from scratch.
# Takes no arguments. Installs Tart itself; ./install.sh never needs it.
set -euo pipefail

repo="${0:A:h:h}"
base=tahoe-base
vm=dotfiles-test
image=ghcr.io/cirruslabs/macos-tahoe-base:latest

source "$repo/lib/common.sh"

[[ -t 0 ]] || { print -u2 "needs a terminal"; exit 1; }

load_brew
if ! command -v brew >/dev/null || ! command -v tart >/dev/null; then
  read -r "ans?Install Homebrew and/or Tart to run this VM test? [y/N] "
  [[ "$ans" == [yY]* ]] || exit 0
  command -v brew >/dev/null || run_module 10-homebrew
  command -v tart >/dev/null || {
    log "installing Tart"
    brew trust --formula openai/tools/softnet
    brew_install openai/tools/tart
  }
fi

local_vms=(${(f)"$(tart list --source local --quiet)"})

if (( ! ${local_vms[(Ie)$base]} )); then
  print "Pulling $image (about 25 GB)"
  tart clone "$image" "$base"
fi

if (( ${local_vms[(Ie)$vm]} )); then
  read -r "ans?Delete the existing $vm VM and start fresh? [y/N] "
  [[ "$ans" == [yY]* ]] || exit 0
  tart stop "$vm" 2>/dev/null || true
  tart delete "$vm"
fi
tart clone "$base" "$vm"

cat <<MSG

VM window opens in about a minute. Log in as admin / admin, open Terminal and run:

  zsh "/Volumes/My Shared Files/dotfiles/install.sh"

The repo is mounted read-write, so gitignored build files land in $repo.
Close the window to stop the VM.
MSG

exec tart run --dir="dotfiles:$repo" "$vm"
