#!/usr/bin/env zsh
# fish shell with PATH setup, robbyrussell style prompt and the colors-demo script
source "$DOTFILES_ROOT/lib/common.sh"
load_brew
dir="${0:A:h}"

ensure_formula fish
ensure_symlink "$dir/config.fish" "$HOME/.config/fish/config.fish"
ensure_symlink "$dir/functions/fish_prompt.fish" "$HOME/.config/fish/functions/fish_prompt.fish"
ensure_symlink "$dir/colors-demo" "$HOME/.local/bin/colors-demo"
