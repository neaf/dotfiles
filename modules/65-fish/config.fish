# PATH: iTerm starts fish directly, so nothing else sets up Homebrew or ~/.local/bin.
/opt/homebrew/bin/brew shellenv | source
fish_add_path ~/.local/bin
