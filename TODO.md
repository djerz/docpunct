# docpunct TODO

## Resumable status

- Framework and initial feature scaffolding have been generated.
- `../mydotfiles` was inspected.
- Safe dotfiles were imported unchanged into `dotfiles/` and listed in `features/dotfiles/files.txt`.
- `docpunct_v4.md` is the latest spec and records decisions made through the current session.
- `HOWTO.md` has been updated to match the v4 feature set and implemented behavior.
- Dependency cycle detection has been added for install/update dependency graphs.
- `debian-cli-packages` is unchanged and accepted as the current CLI package list.
- `debian-gui-packages` contains only distro-repository GUI packages plus `desktop-file-utils` for Neovide desktop entry support.
- Third-party APT repository GUI apps are modeled as separate features: `brave-browser`, `visual-studio-code`, and `google-chrome`.

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
  - `brave-browser`
  - `visual-studio-code`
  - `google-chrome`
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
- Updated `HOWTO.md` to reflect the v4 feature set and implemented behavior.
- Added dependency cycle detection before install/update traversal.
- Updated `debian-gui-packages/packages.txt` to install `keepassxc`, `meld`, `gnome-icon-theme`, `adwaita-icon-theme-full`, and retained `desktop-file-utils` for Neovide.
- Added third-party APT repository features for Brave Browser, Visual Studio Code, and Google Chrome. Each feature owns its package, source file, and signing key.
- Added `docpunct_v4.md` as the latest specification snapshot for future resume sessions.

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
- `DOCPUNCT_CACHE_DIR=/tmp/docpunct-test-cache ./bin/docpunct list`
- `DOCPUNCT_CACHE_DIR=/tmp/docpunct-test-cache ./bin/docpunct status`
- fake-home dotfiles install/remove smoke tests
- `desktop-file-validate` on generated Neovide desktop file
- Git Credential Manager latest-release selector against current upstream release metadata
- removal refusal when `dotfiles` depends on installed `git-credential-manager`
- dependency cycle refusal using a temporary fake feature tree
- new third-party APT feature scripts pass `bash -n`
- new third-party APT feature scripts are executable

## Pending clarification

1. `.gitconfig-private` was not imported yet because its name indicates private data, although the provided file is empty.

## Remaining work

- Decide whether to import the empty `.gitconfig-private`.
- Decide whether `docpunct update FEATURE` should strictly fail when the feature is not installed, as specified, or whether the implementation/spec should keep the current install-after-success behavior.
- Decide whether `docpunct install FEATURE` should return immediately for an already-installed requested feature before resolving dependencies.
- Add install failure rollback that attempts `remove.sh` after a failed install script.
- Consider signature/checksum validation for Git Credential Manager release assets.
- Install-test APT/sudo-backed features only after explicit user approval.

## Known issues

- `docpunct update FEATURE` currently marks an uninstalled feature as installed after a successful update script; v4 says update should fail when the feature is not installed.
- `docpunct install FEATURE` resolves dependencies before checking whether `FEATURE` is already installed; this may install missing dependencies for an already-installed parent feature.
- Install failure logs are kept, but install failure rollback via `remove.sh` is not implemented.
- Git Credential Manager package signature validation is not implemented.
- Neovim removal currently removes the user binary/runtime path but leaves the source checkout under `~/.cache/docpunct/src/neovim`.
- Neovide is installed with `cargo install --locked neovide`, not from a managed source checkout.
- The Git Credential Manager installer has been API-selector tested but not install-tested because it downloads a `.deb` and invokes `sudo dpkg`.
- Package feature scripts have not been run because they invoke APT/sudo and alter the host.
- Third-party APT repository feature scripts have not been run because they download signing keys/source configuration and invoke APT/sudo.

## Next steps

1. Review and commit the current repository state.
2. In the next implementation session, make update semantics match the v4 spec by failing `docpunct update FEATURE` when `FEATURE` is not installed.
3. After that, consider making install return immediately when the requested feature is already installed before resolving dependencies.
4. Later, decide whether to import the empty `.gitconfig-private`.
5. Later, consider signature/checksum validation for Git Credential Manager release assets.
