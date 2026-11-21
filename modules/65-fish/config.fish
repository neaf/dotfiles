# PATH: iTerm starts fish directly, so nothing else sets up Homebrew or ~/.local/bin.
/opt/homebrew/bin/brew shellenv | source
fish_add_path ~/.local/bin

# git abbreviations expand in place when you press space or enter
abbr -a gst git status
abbr -a gu git pull --rebase
abbr -a gco git checkout
abbr -a gd git diff

# zoxide: j <part of a path> jumps to the best frecency match, ji picks interactively
zoxide init fish --cmd j | source
