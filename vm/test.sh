#!/usr/bin/env zsh
# Boots a fresh macOS VM (Tart) with this repo mounted, to try ./install.sh from scratch.
# Takes no arguments. Needs Tart: brew trust --formula openai/tools/softnet; brew install openai/tools/tart
set -euo pipefail

repo="${0:A:h:h}"
base=tahoe-base
vm=dotfiles-test
image=ghcr.io/cirruslabs/macos-tahoe-base:latest

command -v tart >/dev/null || { print -u2 "tart missing, see the header of this file"; exit 1; }
[[ -t 0 ]] || { print -u2 "needs a terminal"; exit 1; }

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
