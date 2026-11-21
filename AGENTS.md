# dotfiles

Idempotent setup for a personal Mac. Run `./install.sh`, tick modules in the checklist, rerun any time.

## Rules for this repo

- `install.sh` takes no arguments. It asks for everything through the checklist.
- A module is `modules/NN-name/setup.sh`. Line 2 is the checklist description. The number sets the order.
- Every step checks state first and changes nothing when it is already right. Use the helpers in `lib/common.sh` (`ensure_symlink`, `ensure_cask <name> [App Name]`, `ensure_formula`, `load_brew`, `run_module`).
- A feature that needs another module calls `run_module <folder>` at the top. There is no dependency resolver.
- `ensure_symlink` moves an existing file to `<target>.bak` once. Repo files are linked, so edits go to the repo.
- Never commit secrets, the Jellyfin user database, or app state. Machine-only artifacts go in a module `.gitignore`.
- Scripts are zsh. Traps: `modules` is a read-only variable, macOS has no `timeout`, `echo ====` fails because zsh expands `=`, and `plistlib.load` needs a seekable stream (use `loads(read())`).

## Layout

| Module | Does |
|---|---|
| 05-dock | Removes Apple apps from the Dock once, sets icon size 40 |
| 10-homebrew, 15-data-dirs | Homebrew, `~/Data/Media/{Downloads,Video/TV,Video/Movies,Music}` |
| 20-apps, 30-ssh | 1Password and Brave, SSH config for the 1Password agent, waits for GitHub |
| 40-claude-code, 45-opencode, 50-agent-harness | CLIs, and `neaf/agent-harness` cloned over SSH |
| 65-fish, 70-iterm2 | fish config and prompt, iTerm2 prefs folder, Fish profile, neutral dark colors |
| 72-karabiner | Keyboard rules |
| 74-hammerspoon, 75-display-switch, 76-audio-switch, 77-window-management | Hammerspoon host and its features (hyper = ctrl+alt+cmd+shift) |
| 80-python, 85-transmission, 86-spotify, 90-jellyfin | uv and Python, apps, Jellyfin with seeded config |

Decisions: fish only (no zsh module), started by the iTerm2 Fish profile while the login shell stays zsh. Hammerspoon replaces Rectangle. 1Password holds the SSH key, GitHub trusts its public half, a new Mac never runs `ssh-keygen`.

## Testing in a VM

`vm/test.sh` clones a fresh macOS VM with Tart and mounts this repo. In the guest run `zsh "/Volumes/My Shared Files/dotfiles/install.sh"`. Login `admin` / `admin`.

- Install Tart from the `openai/tools` tap: `brew trust --formula openai/tools/softnet`, then `brew install openai/tools/tart`. The old `cirruslabs/cli` tap has no Tart.
- From the host, `tart exec dotfiles-test <cmd>` runs a command in the guest. Pass stdin with `tart exec -i`, otherwise piped input is dropped.
- `vnc://admin:admin@<tart ip dotfiles-test>` opens the guest screen while it runs without a window.
- The VM has no Touch ID, audio devices or external display. `30-ssh` waits until 1Password is signed in with the SSH agent on (Settings > Developer) and the key is in the Private vault. Skip `30-ssh` and `50-agent-harness` for a run without a key.
- The repo mount is read-write: `76-audio-switch` writes gitignored files (`bin/`, `camillagui_backend/`, logs) into the host repo.

## Not done yet

- `gh auth login` module.
- Live links for `output.lua`, `display.lua` and `tempora.lua` still point into the old `~/dotfiles`. Running `75` and `76` moves them and the CamillaDSP agent here.
- `tempora.lua` stays outside until Tempora ships its own helper. A Bitwig module is planned.
- iTerm2 reads the repo prefs folder only after `70-iterm2` runs and iTerm2 restarts. Colors can also be chosen from the `neutral-dark` preset.
- Per-machine stacks (Python, Android, Swift, Java) with a checklist question, version managers per stack (uv, SDKMAN), no universal manager.
