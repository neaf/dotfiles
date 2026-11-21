#!/usr/bin/env zsh
# External display toggle on hyper+D
source "$DOTFILES_ROOT/lib/common.sh"
dir="${0:A:h}"
run_module 32-hammerspoon

hs_feature "${0:A:h}/display.lua"

# extdisplay needs the Xcode command line tools for clang. Rebuilt when the source is newer.
tool="$HOME/.hammerspoon/bin/extdisplay"
if [[ ! -x "$tool" || "$dir/extdisplay.c" -nt "$tool" ]]; then
  command -v clang >/dev/null || die "clang missing, run xcode-select --install"
  mkdir -p "${tool:h}"
  clang "$dir/extdisplay.c" -o "$tool" -framework CoreGraphics -framework ApplicationServices
  log "built extdisplay"
fi
