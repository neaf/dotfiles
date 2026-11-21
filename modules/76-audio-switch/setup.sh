#!/usr/bin/env zsh
# Audio output menubar (hyper+P/I/O) routing through CamillaDSP, BlackHole 2ch and CamillaGUI (needs Hammerspoon)
source "$DOTFILES_ROOT/lib/common.sh"
load_brew
dir="${0:A:h}"
run_module 74-hammerspoon

ensure_symlink "$dir/output.lua" "$HOME/.hammerspoon/output.lua"
camilladsp_version=v4.1.3
camillagui_version=v4.1.0

ensure_cask blackhole-2ch
mkdir -p "$dir/bin" "$dir/coeffs"

case "$(uname -m)" in
  arm64) dsp_arch=aarch64 gui_arch=aarch64 ;;
  *)     dsp_arch=amd64   gui_arch=intel ;;
esac
if [[ ! -x "$dir/bin/camilladsp" ]]; then
  log "downloading camilladsp $camilladsp_version"
  curl -fsSL "https://github.com/HEnquist/camilladsp/releases/download/$camilladsp_version/camilladsp-macos-$dsp_arch.tar.gz" \
    | tar -xz -C "$dir/bin"
fi
if [[ ! -d "$dir/camillagui_backend" ]]; then
  log "downloading camillagui $camillagui_version"
  curl -fsSL "https://github.com/HEnquist/camillagui-backend/releases/download/$camillagui_version/bundle_macos_$gui_arch.tar.gz" \
    | tar -xz -C "$dir"
fi
sed "s#__DIR__#$dir#g" "$dir/camillagui.yml.template" > "$dir/camillagui.yml"

# The launchd agent is rewritten and reloaded only when its content changes.
label=com.actus.camilladsp.ka6
plist="$HOME/Library/LaunchAgents/$label.plist"
want="$(sed "s#__DIR__#$dir#g" "$dir/$label.plist.template")"
if [[ ! -f "$plist" || "$(<"$plist")" != "$want" ]] || ! launchctl print "gui/$UID/$label" >/dev/null 2>&1; then
  mkdir -p "${plist:h}"
  print -r -- "$want" > "$plist"
  launchctl bootout "gui/$UID" "$plist" 2>/dev/null || true
  launchctl bootstrap "gui/$UID" "$plist"
  log "camilladsp agent loaded"
fi
