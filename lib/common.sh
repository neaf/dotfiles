#!/usr/bin/env zsh
# Shared helpers. Every function checks state first, so re-running changes nothing.

DOTFILES_ROOT="${DOTFILES_ROOT:-${0:A:h:h}}"

log()  { print -P "%F{blue}==>%f $*"; }
warn() { print -P "%F{yellow}warn%f $*" >&2; }
die()  { print -P "%F{red}error%f $*" >&2; exit 1; }

# ensure_symlink <source in repo> <target path>
# Skips when the link is correct. Moves an existing file to <target>.bak once.
ensure_symlink() {
  local src="$1" dst="$2"
  [[ -e "$src" ]] || die "missing source: $src"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    return 0
  fi
  mkdir -p "${dst:h}"
  if [[ -e "$dst" || -L "$dst" ]]; then
    [[ -e "$dst.bak" ]] && die "backup exists: $dst.bak"
    mv "$dst" "$dst.bak"
    warn "moved $dst to $dst.bak"
  fi
  ln -s "$src" "$dst"
  log "linked $dst"
}

# ensure_cask <name> [App Name]: install only when absent.
# The app name catches apps installed by hand, which brew refuses to overwrite.
ensure_cask() {
  brew list --cask "$1" >/dev/null 2>&1 && return 0
  [[ -n "${2:-}" && -d "/Applications/$2.app" ]] && return 0
  log "installing cask $1"
  brew install --cask "$1"
}
ensure_formula() {
  brew list --formula "${1:t}" >/dev/null 2>&1 && return 0
  log "installing formula $1"
  brew install "$1"
}

# Puts brew on PATH for this process when it is installed but not yet in the shell.
load_brew() {
  command -v brew >/dev/null && return 0
  [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
}
