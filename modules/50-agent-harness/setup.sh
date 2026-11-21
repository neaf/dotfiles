#!/usr/bin/env zsh
# neaf/agent-harness: clone over SSH, pull, apply to Claude Code and opencode
source "$DOTFILES_ROOT/lib/common.sh"
dir="$HOME/dev/agent-harness"

if [[ -d "$dir/.git" ]]; then
  if [[ -z "$(git -C "$dir" status --porcelain)" ]]; then
    git -C "$dir" pull --ff-only
  else
    warn "agent-harness has local changes, skipping pull"
  fi
else
  git clone git@github.com:neaf/agent-harness.git "$dir"
fi

# install.py exits 1 on drift. It prompts before replacing files.
if "$dir/install.py" --check >/dev/null; then
  log "agent-harness config up to date"
else
  "$dir/install.py"
fi
