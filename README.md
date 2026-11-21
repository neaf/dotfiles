# dotfiles

Idempotent setup for a personal Mac. Run `./install.sh`, tick modules in the checklist, rerun any time.

## Layout

| Phase | Modules | Do |
|---|---|---|
| 1 | 10-homebrew | Homebrew |
| 2 | 20-fish, 21-iterm2, 22-claude-code, 23-opencode, 24-python | fish config and prompt, iTerm2 prefs folder and Fish profile with neutral dark colors, CLIs, uv and Python |
| 3 | 30-dock, 31-karabiner, 32-hammerspoon | Dock without Apple apps and icon size 40, keyboard rules, Hammerspoon host |
| 4 | 40-display-switch, 41-audio-switch, 42-window-management | Hammerspoon features (hyper = ctrl+alt+cmd+shift) |
| 5 | 50-apps | 1Password and Brave |
| 6 | 60-ssh | SSH config for the 1Password agent, waits for GitHub |
| 7 | 70-agent-harness | `neaf/agent-harness` cloned over SSH |
| 8 | 80-data-dirs | `~/Data/Media/{Downloads,Video/TV,Video/Movies,Music}` |
| 9 | 90-transmission, 91-spotify, 92-jellyfin | Apps, Jellyfin with seeded config |

A module is `modules/NN-name/setup.sh`. The tens digit of its number sets the phase; phases run in order, modules in one phase run in parallel. Every step checks state first and changes nothing when it is already right.

## Testing in a VM

`vm/test.sh` clones a fresh macOS VM with Tart and mounts this repo. In the guest run `zsh "/Volumes/My Shared Files/dotfiles/install.sh"`. Login `admin` / `admin`.

See `AGENTS.md` for the full rules, VM details, and open items.
