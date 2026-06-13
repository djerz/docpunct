# docpunct TODO

## Resumable status

- Framework and initial feature scaffolding have been generated.
- `../mydotfiles` was inspected.
- Safe dotfiles were imported unchanged into `dotfiles/` and listed in `features/dotfiles/files.txt`.
- `docpunct_v3.md` records the decisions made during this implementation session.

## Done

- Added Bash CLI at `bin/docpunct`.
- Added `justfile` convenience commands.
- Added feature directories and manifests for:
  - `core`
  - `dotfiles`
  - `debian-cli-packages`
  - `debian-gui-packages`
  - `git-credential-manager`
  - `rust`
  - `node`
  - `python-uv`
  - `neovim`
  - `neovide`
- Added install/update/remove scripts where needed.
- Added dependency resolution for install/update.
- Added conservative dependency guard for removal.
- Fixed removal guard so dependents are reported instead of exiting silently.
- Added state, log, source, download, and dotfile backup directories under `~/.cache/docpunct`.
- Added dotfile symlink install, backup, restore, and relink support.
- Imported public dotfiles from `../mydotfiles`.
- Imported `.gitconfig` with `credential.helper = manager`.
- Imported `.config/nvim/lua/plugins/copilotchat.lua` with the hardcoded Copilot Node override removed.
- Left `.gitconfig-private` out of the repository.
- Added Git Credential Manager installer feature:
  - queries the latest GitHub release dynamically
  - selects `gcm-linux-x64-*.deb` for Debian `amd64`
  - selects `gcm-linux-arm64-*.deb` for Debian `arm64`
  - installs with `sudo dpkg -i`
  - runs `git-credential-manager configure`
- Wired dependencies:
  - `git-credential-manager` depends on `debian-cli-packages`
  - `dotfiles` depends on `git-credential-manager`
  - `core` includes `git-credential-manager` before `dotfiles`
- Added Neovide desktop entry template and install/remove handling in the `neovide` feature.

## Imported dotfiles

- `.bashrc`
- `.gitconfig`
- `.config/nvim/init.lua`
- `.config/nvim/lazy-lock.json`
- `.config/nvim/readme.txt`
- `.config/nvim/lua/config/keymaps.lua`
- `.config/nvim/lua/config/lazy.lua`
- `.config/nvim/lua/plugins/copilotchat.lua`
- `.config/nvim/lua/plugins/diffview.lua`
- `.config/nvim/lua/plugins/hexview.lua`
- `.config/nvim/lua/plugins/init.lua`
- `.config/nvim/lua/plugins/telescope.lua`
- `.config/nvim/lua/plugins/web-devicons.lua`

## Verified

- `bash -n bin/docpunct features/*/*.sh`
- `./bin/docpunct list`
- `./bin/docpunct status`
- fake-home dotfiles install/remove smoke tests
- `desktop-file-validate` on generated Neovide desktop file
- Git Credential Manager latest-release selector against current upstream release metadata
- removal refusal when `dotfiles` depends on installed `git-credential-manager`

## Pending clarification

1. `.gitconfig-private` was not imported yet because its name indicates private data, although the provided file is empty.

## Known issues

- Dependency cycle detection is not implemented yet.
- `docpunct update FEATURE` currently marks an uninstalled feature as installed after a successful update script; v2 originally said update should fail when the feature is not installed.
- `docpunct install FEATURE` resolves dependencies before checking whether `FEATURE` is already installed; this may install missing dependencies for an already-installed parent feature.
- Install failure logs are kept, but install failure rollback via `remove.sh` is not implemented.
- Git Credential Manager package signature validation is not implemented.
- Neovim removal currently removes the user binary/runtime path but leaves the source checkout under `~/.cache/docpunct/src/neovim`.
- Neovide is installed with `cargo install --locked neovide`, not from a managed source checkout.
- The Git Credential Manager installer has been API-selector tested but not install-tested because it downloads a `.deb` and invokes `sudo dpkg`.
- Package feature scripts have not been run because they invoke APT/sudo and alter the host.

## Next steps

1. Review and commit the current repository state.
2. In the next session, update `HOWTO.md` to reflect `docpunct_v3.md`, especially Git Credential Manager and Neovide desktop integration.
3. Decide whether to import the empty `.gitconfig-private`.
4. Decide whether to make update semantics match v2 strictly or update the spec to accept the current behavior.
5. Add dependency cycle detection.
6. Consider signature/checksum validation for Git Credential Manager release assets.
