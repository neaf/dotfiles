#!/usr/bin/env zsh
# External display toggle in the menubar and on hyper+D (needs Hammerspoon)
source "$DOTFILES_ROOT/lib/common.sh"
dir="${0:A:h}"
run_module 74-hammerspoon

ensure_symlink "$dir/display.lua" "$HOME/.hammerspoon/display.lua"

# extdisplay needs the Xcode command line tools for clang. Rebuilt when the source is newer.
tool="$HOME/.hammerspoon/bin/extdisplay"
if [[ ! -x "$tool" || "$dir/extdisplay.c" -nt "$tool" ]]; then
  command -v clang >/dev/null || die "clang missing, run xcode-select --install"
  mkdir -p "${tool:h}"
  clang "$dir/extdisplay.c" -o "$tool" -framework CoreGraphics -framework ApplicationServices
  log "built extdisplay"
fi
