# docpunct TODO

## Resumable status

- Framework and initial feature scaffolding have been generated.
- `../mydotfiles` was inspected.
- Safe dotfiles were imported unchanged into `dotfiles/` and listed in `features/dotfiles/files.txt`.
- `docpunct_v6.md` is the latest spec and records decisions made through the current session.
- `HOWTO.md` has been updated to match the v6 feature set and implemented behavior.
- Dependency cycle detection has been added for install/update dependency graphs.
- `debian-cli-packages` is unchanged and accepted as the current CLI package list.
- `debian-gui-packages` contains only distro-repository GUI packages plus `desktop-file-utils` for Neovide desktop entry support.
- Third-party APT repository packages are modeled as separate features: `brave-browser`, `visual-studio-code`, `google-chrome`, and `docker`.
- Docker was installed with docpunct in the previous session, the sibling `../dockerfiles` ShellCheck image was usable, and this repository now has a repeatable `just shellcheck` target.
- A first testing architecture is in place:
  - `just test-smoke` runs host-safe Bash smoke tests with temporary home/cache directories.
  - `just test-container ubuntu=VERSION` runs integration tests in disposable Ubuntu containers for 22.04, 24.04, or 26.04.
  - `just test-containers` runs the container test matrix.
  - `just test-docker-feature ubuntu=VERSION` runs the Docker feature in a separate privileged container.
  - `just test` currently runs ShellCheck and host-safe smoke tests only.
- Every `just` target now delegates to an equivalent `./bin/docpunct` command so the test suite can be run without `just`.
- Future sessions should always run tests appropriate to the completed task:
  - shell script changes: `./bin/docpunct shellcheck` or `just shellcheck`
  - core behavior changes: `./bin/docpunct test` or `just test`
  - package/container behavior changes: the matching `test-container`,
    `test-containers`, `test-docker-feature`, or feature-specific target
- Future sessions are allowed to run any test target without asking first,
  including container tests that pull images or run APT/network work inside
  containers.

## Done

- Added Bash CLI at `bin/docpunct`.
- Added `justfile` convenience commands.
- Added feature directories and manifests for:
  - `core`
  - `dotfiles`
  - `fd-find`
  - `debian-cli-packages`
  - `debian-gui-packages`
  - `desktop-apps`
  - `git-credential-manager`
  - `rust`
  - `node`
  - `python-uv`
  - `neovim`
  - `neovide`
  - `brave-browser`
  - `visual-studio-code`
  - `google-chrome`
  - `doublecmd`
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
- Updated `HOWTO.md` to reflect the latest feature set and implemented behavior.
- Added dependency cycle detection before install/update traversal.
- Updated `debian-gui-packages/packages.txt` to install `keepassxc`, `meld`, `gnome-icon-theme`, `adwaita-icon-theme-full`, and retained `desktop-file-utils` for Neovide.
- Added third-party APT repository features for Brave Browser, Visual Studio Code, and Google Chrome. Each feature owns its package, source file, and signing key.
- Added `docpunct_v4.md` as the latest specification snapshot for future resume sessions.
- Changed `docpunct update FEATURE` to fail when `FEATURE` or any updated dependency is not installed, matching the spec.
- Added a `docker` feature that installs Docker Engine from Docker's official APT repository after removing conflicting Ubuntu/distro Docker packages.
- Added architecture guards for third-party APT package features and Docker suite handling for Ubuntu 22.04, 24.04, and 26.04.
- Docker install adds the target user to the `docker` group when needed and Docker removal removes only the group membership it added.
- Docker removal leaves the `docker` group in place and prints a manual `sudo groupdel docker` cleanup hint when the group still exists.
- Added `docpunct_v5.md` as the latest specification snapshot for future resume sessions.
- Added `docpunct_v6.md` as the latest specification snapshot for future resume sessions.
- Cleaned the sibling `../dockerfiles` repository so its ShellCheck image references use `ghcr.io/djerz/shellcheck:latest` and other `djerz` GitHub/GHCR references instead of inherited `r.j3ss.co` or Jess references.
- Added a repeatable `just shellcheck` target that runs ShellCheck through `ghcr.io/djerz/shellcheck:latest` with Docker image pulls disabled.
- Added host-safe smoke tests for listing, status, dotfile link/relink/remove behavior, dependency removal guards, update refusal, and dependency cycle refusal.
- Added disposable Ubuntu container integration test scripts and just targets for Ubuntu 22.04, 24.04, and 26.04.
- Added a separate privileged Docker-container test target for the `docker` feature.
- Added matching `./bin/docpunct` commands for all `justfile` targets, including bootstrap and test targets.
- Recorded the standing project practice that future sessions should run tests appropriate to the change.
- Added a `doublecmd` feature that installs the latest Double Commander GitHub release from the portable Qt6 Linux tarball for the local architecture.
- Added a separate non-privileged Double Commander container test target.
- Added a `desktop-apps` meta-feature for GUI desktop applications.
- Fixed Docker feature user selection so `sudo -u USER` contexts do not incorrectly target `root` through `SUDO_USER=root`.
- Added `util-linux-extra` as an optional `debian-cli-packages` package because Ubuntu 22.04 does not provide it; `ripgrep` was already present.
- Moved `fd-find` into a separate feature that installs the package and links `~/.local/bin/fd` to `fdfind`; `debian-cli-packages` depends on it.

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
- update refusal for an uninstalled feature using an isolated cache
- update refusal for an uninstalled dependency using a temporary fake feature tree
- Docker feature scripts pass `bash -n`
- Docker feature scripts are executable
- Third-party APT feature scripts have architecture compatibility guards.
- ShellCheck passes for `bin/docpunct` and `features/*/*.sh` through the Docker image.
- ShellCheck passes for test scripts through the Docker image.
- `tests/smoke.sh`
- `./bin/docpunct test`
- `./bin/docpunct test-containers` with Ubuntu 22.04, 24.04, and 26.04.
- `./bin/docpunct test-docker-feature 24.04`
- Double Commander latest-release asset selector against current upstream release metadata.
- `./bin/docpunct test-doublecmd-feature 24.04`
- Docker feature group membership add/remove behavior in `./bin/docpunct test-docker-feature 24.04`.
- `./bin/docpunct test-containers` after adding optional `util-linux-extra`.
- `./bin/docpunct test-containers` after moving `fd-find` into its own feature and verifying the `fd` symlink.
- `git diff --check`

## Pending clarification

1. `.gitconfig-private` was not imported yet because its name indicates private data, although the provided file is empty.

## Remaining work

- Decide whether to import the empty `.gitconfig-private`.
- Decide whether `docpunct install FEATURE` should return immediately for an already-installed requested feature before resolving dependencies.
- Add install failure rollback that attempts `remove.sh` after a failed install script.
- Consider signature/checksum validation for Git Credential Manager release assets.
- Consider signature/checksum validation for Double Commander release assets.

## Known issues

- `docpunct install FEATURE` resolves dependencies before checking whether `FEATURE` is already installed; this may install missing dependencies for an already-installed parent feature.
- Install failure logs are kept, but install failure rollback via `remove.sh` is not implemented.
- Git Credential Manager package signature validation is not implemented.
- Double Commander release asset signature/checksum validation is not implemented.
- Neovim removal currently removes the user binary/runtime path but leaves the source checkout under `~/.cache/docpunct/src/neovim`.
- Neovide is installed with `cargo install --locked neovide`, not from a managed source checkout.
- The Git Credential Manager installer has been API-selector tested but not install-tested because it downloads a `.deb` and invokes `sudo dpkg`.
- APT/sudo-backed package feature scripts have been tested in disposable containers, but most have not been install-tested directly on the host.
- Third-party APT repository feature scripts other than Docker have not been install-tested on the host because they download signing keys/source configuration and invoke APT/sudo.
- The sibling `../dockerfiles` repository has local cleanup edits that should be reviewed, committed, and pushed separately from this docpunct repository if not already done.

## Next steps

1. Review and commit the current repository state.
2. Push the committed docpunct changes.
3. In a later session, consider making install return immediately when the requested feature is already installed before resolving dependencies.
4. Later, decide whether to import the empty `.gitconfig-private`.
5. Later, consider signature/checksum validation for Git Credential Manager and Double Commander release assets.
