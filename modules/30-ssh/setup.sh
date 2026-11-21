#!/usr/bin/env zsh
# SSH config for the 1Password agent, waits until GitHub accepts the key
source "$DOTFILES_ROOT/lib/common.sh"

ensure_symlink "${0:A:h}/config" "$HOME/.ssh/config"

github_ok() {
  # GitHub exits 1 on success because it offers no shell.
  ssh -T -o BatchMode=yes -o StrictHostKeyChecking=accept-new git@github.com 2>&1 \
    | grep -q "successfully authenticated"
}

until github_ok; do
  warn "GitHub rejected SSH. In 1Password: sign in, Settings > Developer > Use the SSH agent, tick 'Display key names when authorizing connections', add your GitHub key."
  [[ -t 0 ]] || die "no terminal to wait on, fix 1Password and rerun"
  read -r "?Press Enter to retry, Ctrl-C to stop. "
done
log "github ssh ok"
