# dotfiles

Idempotent setup for a personal Mac. Run `./install.sh`, tick modules in the checklist, rerun any time.

## Rules for this repo

- `install.sh` takes no arguments. It asks for everything through the checklist.
- A module is `modules/NN-name/setup.sh`. Line 2 is the checklist description. The number sets the phase and order.
- Every step checks state first and changes nothing when it is already right. Use the helpers in `lib/common.sh` (`ensure_symlink`, `ensure_cask <name> [App Name]`, `ensure_formula`, `load_brew`, `run_module`).
- A feature that needs another module calls `run_module <folder>` at the top. There is no dependency resolver.
- `ensure_symlink` moves an existing file to `<target>.bak` once. Repo files are linked, so edits go to the repo.
- Docs and comments say what the repo does. They do not record what it replaced or why something was dropped.
- Never commit secrets, the Jellyfin user database, or app state. Machine-only artifacts go in a module `.gitignore`.
- Scripts are zsh. Traps: `modules` is a read-only variable, macOS has no `timeout`, `echo ====` fails because zsh expands `=`, and `plistlib.load` needs a seekable stream (use `loads(read())`).

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

The tens digit of a module number is its phase. Phases run in order, modules in one phase run in parallel with logs in a temp folder. A module that needs another from the same phase calls `run_module` and so belongs in a later phase.

Decisions: fish only (no zsh module), started by the iTerm2 Fish profile while the login shell stays zsh. 1Password holds the SSH key, GitHub trusts its public half, a new Mac never runs `ssh-keygen`.

## Testing in a VM

`vm/test.sh` clones a fresh macOS VM with Tart and mounts this repo. In the guest run `zsh "/Volumes/My Shared Files/dotfiles/install.sh"`. Login `admin` / `admin`.

- `vm/test.sh` installs Tart itself, from the `openai/tools` tap (the old `cirruslabs/cli` tap has no Tart). `./install.sh` never needs Tart.
- From the host, `tart exec dotfiles-test <cmd>` runs a command in the guest. Pass stdin with `tart exec -i`, otherwise piped input is dropped.
- `vnc://admin:admin@<tart ip dotfiles-test>` opens the guest screen while it runs without a window.
- The VM has no Touch ID, audio devices or external display. `60-ssh` waits until 1Password is signed in with the SSH agent on (Settings > Developer) and the key is in the Private vault. Skip `60-ssh` and `70-agent-harness` for a run without a key.
- The repo mount is read-write: `41-audio-switch` writes gitignored files (`bin/`, `camillagui_backend/`, logs) into the host repo.

## Not done yet

- `gh auth login` module.
- iTerm2 reads the repo prefs folder only after `21-iterm2` runs and iTerm2 restarts. Colors can also be chosen from the `neutral-dark` preset.
- Per-machine stacks (Python, Android, Swift, Java) with a checklist question, version managers per stack (uv, SDKMAN), no universal manager.

## Music production

- `tempora.lua` stays outside this repo until Tempora ships its own helper.
- A Bitwig module is planned.
