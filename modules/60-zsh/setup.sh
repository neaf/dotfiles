#!/usr/bin/env zsh
# zsh config (~/.zshrc) with fzf, zoxide, fzf-tab, syntax highlighting, GNU tools
source "$DOTFILES_ROOT/lib/common.sh"
load_brew

for f in zoxide fzf fd fzf-tab zsh-syntax-highlighting coreutils findutils gnu-sed grep; do
  ensure_formula $f
done
ensure_symlink "${0:A:h}/zshrc" "$HOME/.zshrc"
