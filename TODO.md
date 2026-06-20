# docpunct TODO

## Resumable status

- Framework and initial feature scaffolding have been generated.
- `../mydotfiles` was inspected.
- Safe dotfiles were imported into `dotfiles/` and listed in
  `features/dotfiles/files.txt`.
- `arch/docpunct_arch.md` is the single living architecture specification and
  records decisions made through the current session.
- `HOWTO.md` has been updated to match the living architecture and implemented
  behavior.
- Dependency cycle detection has been added for install/update dependency graphs.
- `debian-cli-packages` includes `libicu-dev` so Git Credential Manager's
  bundled .NET runtime can start on fresh Ubuntu installations, including
  Ubuntu 26.04.
- `debian-gui-packages` contains distro-repository GUI packages plus
  `desktop-file-utils`, `libfontconfig1-dev`, `libfreetype6-dev`, and
  `wl-clipboard`, `xclip`, and `libqt6printsupport6` for Neovide desktop entry
  support, Neovide Cargo link-time requirements, Neovide clipboard integration,
  and the Double Commander Qt6 runtime.
- Third-party APT repository packages are modeled as separate features: `brave-browser`, `visual-studio-code`, `google-chrome`, and `docker`.
- Docker was installed with docpunct in the previous session, the sibling `../dockerfiles` ShellCheck image was usable, and this repository now has a repeatable `just shellcheck` target.
- A first testing architecture is in place:
  - `just test-smoke` runs host-safe Bash smoke tests with temporary home/cache directories.
  - `just test-container ubuntu=VERSION` runs integration tests in disposable Ubuntu containers for 22.04, 24.04, or 26.04.
  - `just test-containers` runs the container test matrix.
  - `just test-docker-feature ubuntu=VERSION` runs the Docker feature in a separate privileged container.
  - `just test` currently runs ShellCheck and host-safe smoke tests only.
  - `just test-neovide-feature ubuntu=VERSION` runs a real Neovide install in
    a separate non-privileged container.
  - `just test-doublecmd-feature ubuntu=VERSION` runs a real Double Commander
    install in a separate non-privileged container and checks the installed
    binary for unresolved shared libraries with `ldd`.
- Every `just` target now delegates to an equivalent `./bin/docpunct` command so the test suite can be run without `just`.
- `docpunct update FEATURE` now still requires the requested feature to be
  installed, but installs newly introduced dependencies before updating the
  requested feature. This allows dependency recipe changes to apply without a
  remove/install loop.
- `docpunct install FEATURE` now returns immediately when the requested
  feature is already installed, before validating or traversing dependencies.
- Failed feature installs now attempt the same feature's `remove.sh` as
  best-effort cleanup, retain the original install error log, and leave the
  feature unmarked.
- `dotfiles` install and update both use `features/dotfiles/reconcile.sh`, so
  new dotfile entries added to `files.txt` get the same backup-and-link
  handling during update as during initial install.
- Shared shell environment setup now lives in `session-env.sh`, with
  `.profile` and `.bashrc` using additive marked blocks so existing host shell
  configuration is preserved. `bash-ext.sh` owns personal Bash aliases and NVM
  completion.
- Future sessions should always run tests appropriate to the completed task:
  - shell script changes: `./bin/docpunct shellcheck` or `just shellcheck`
  - core behavior changes: `./bin/docpunct test` or `just test`
  - package/container behavior changes: the matching `test-container`,
    `test-containers`, `test-docker-feature`, or feature-specific target
- Future sessions are allowed to run any test target without asking first,
  including container tests that pull images or run APT/network work inside
  containers.
- Future features that invoke Cargo or Rust tools must source
  `$HOME/.cargo/env` themselves before calling those tools; do not rely on
  `.profile`, `.bashrc`, the Rust feature script, or a previous child process
  to update the current feature script environment.
- Before removing APT packages owned by a feature, check whether they are
  shared desktop/system dependencies and warn before implementing removal that
  could cause APT to remove packages such as `ubuntu-desktop`,
  `ubuntu-desktop-minimal`, `gdm3`, `gnome-control-center`, or `nautilus`.

## Done

- Replaced whole-file `.profile` and `.bashrc` symlinks with additive managed
  blocks sourcing shared `session-env.sh` and Bash-specific `bash-ext.sh`
  fragments, including migration from existing docpunct symlinks.
- Consolidated the versioned `docpunct_vX.md` specification snapshots into
  the single living `arch/docpunct_arch.md` document and updated resume/task
  references to use it.
- Made install return immediately for an already-installed requested feature
  before dependency cycle detection or traversal, and added a smoke regression
  covering an installed feature whose manifest names a missing dependency.
- Added best-effort failed-install cleanup through the feature's `remove.sh`,
  including regression coverage for artifact removal, retained install logs,
  and unchanged installed state.
- Added `AIHANDOVER.md` with a concise prompt that directs new sessions to the
  authoritative specification, usage, task, and TODO documents.
- Added `libicu-dev` to `debian-cli-packages`, made the Git Credential Manager
  installer ensure it is present for failed-install retries, and added a
  container assertion after a fresh Ubuntu 26.04 core install exposed Git
  Credential Manager's ICU runtime dependency.

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
- Changed `docpunct update FEATURE` to fail when `FEATURE` is not installed.
  Later behavior was reworked so newly introduced dependencies are installed
  during update.
- Added a `docker` feature that installs Docker Engine from Docker's official APT repository after removing conflicting Ubuntu/distro Docker packages.
- Added architecture guards for third-party APT package features and Docker suite handling for Ubuntu 22.04, 24.04, and 26.04.
- Docker install adds the target user to the `docker` group when needed and Docker removal removes only the group membership it added.
- Docker removal leaves the `docker` group in place and prints a manual `sudo groupdel docker` cleanup hint when the group still exists.
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
- Added Cargo/nvm shell initialization to the imported `.bashrc`; Cargo env
  loading is guarded so shells still start before Rust is installed.
- Fixed Rust and Neovide feature scripts so they source `$HOME/.cargo/env`
  themselves before invoking Rust/Cargo tools.
- Added a host-safe smoke regression proving Neovide install finds Cargo via
  `$HOME/.cargo/env` without requiring `.bashrc` or a new shell session.
- Added `libfontconfig1-dev` and `libfreetype6-dev` to
  `debian-gui-packages` so Neovide can link against Fontconfig and FreeType
  during `cargo install --locked neovide`.
- Added a feature-specific Neovide container test target.
- Fixed dependency traversal so install/update/cycle detection snapshots
  dependency lists before running child feature scripts. This prevents scripts
  such as `apt-get` from consuming the parent dependency stream on stdin and
  skipping later dependencies.
- Split `debian-gui-packages` removal into a dedicated
  `removable-packages.txt` so shared Ubuntu desktop dependencies are installed
  but not removed by docpunct.
- Added a `nerdfonts` feature that installs a curated user-local Nerd Fonts
  set and made `neovide` depend on it.
- Changed Neovim dotfile management from file-level symlinks to a
  directory-level `~/.config/nvim` symlink and added an `update dotfiles`
  migration path for existing docpunct-owned file symlinks.
- Marked the old Neovim file-level symlink migration path as deprecated; remove
  it after existing machines have run `docpunct update dotfiles`.
- Added `features/neovide/neovide.ico` as the Neovide desktop entry icon; the
  Neovide install script copies it to a user-local icon path and the remove
  script removes only that copied icon.
- Updated the imported Telescope config so `<leader>fn` follows symlinks and
  includes hidden/non-ignored files when searching Neovim config.
- Added `libqt6printsupport6` to `debian-gui-packages` because the Double
  Commander Qt6 portable build needs system Qt6 runtime libraries on Ubuntu.
- Strengthened the Double Commander feature container test so it fails when
  `ldd` reports unresolved shared libraries for the installed binary.
- Updated `HOWTO.md` for the Double Commander Qt6 runtime dependency.
- Added `wl-clipboard` and `xclip` to `debian-gui-packages` so
  Neovide/Neovim clipboard integration works on Wayland and X11 sessions.
- Reworked `docpunct update FEATURE` so newly introduced dependencies are
  installed during update while the requested feature itself must already be
  installed.
- Split dotfile reconciliation into `features/dotfiles/reconcile.sh` and made
  both install and update use it.
- Added managed `dotfiles/.profile`, listed `.profile` in
  `features/dotfiles/files.txt`, and moved login-shell PATH setup there from
  `.bashrc`.
- Kept interactive shell behavior in `.bashrc`, including NVM Bash completion,
  while `.profile` handles `$HOME/.local/bin`, Cargo env loading, `NVM_DIR`,
  and `nvm.sh` so `node` follows the NVM-managed default version in
  non-interactive login Bash shells.
- Added a smoke regression proving `.profile` makes an NVM-provided `node`
  available on `PATH`.

## Imported dotfiles

- `.gitconfig`
- `.config/docpunct/session-env.sh`
- `.config/docpunct/bash-ext.sh`
- `.config/nvim`

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
- update installs a newly introduced dependency using a temporary fake feature tree
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
- `bash -n bin/docpunct features/*/*.sh tests/*.sh tests/container/*.sh` after
  fixing Cargo environment handling.
- `./bin/docpunct test-smoke` after fixing Cargo environment handling.
- `bash -n bin/docpunct features/*/*.sh tests/*.sh tests/container/*.sh` after
  fixing Neovide install dependencies and dependency traversal.
- `./bin/docpunct test-smoke` after adding the stdin-consuming dependency
  regression.
- `./bin/docpunct shellcheck` after adding the Neovide feature test target and
  fixing dependency traversal.
- `./bin/docpunct test-neovide-feature 22.04`
- `./bin/docpunct test-neovide-feature 24.04`
- `./bin/docpunct test-neovide-feature 26.04`
- `bash -n bin/docpunct features/*/*.sh tests/*.sh tests/container/*.sh` after
  the v9 session changes.
- `./bin/docpunct test-smoke` after adding conservative GUI package removal,
  Nerd Fonts, Neovide icon handling, Telescope config search behavior, and the
  dotfiles Neovim directory-symlink migration.
- `./bin/docpunct shellcheck` after the v9 shell script changes.
- `./bin/docpunct test` after the v9 shell script changes.
- Nerd Fonts latest-release asset names were verified through the GitHub API
  metadata for `FiraCode.zip`, `Hack.zip`, `JetBrainsMono.zip`, `Noto.zip`,
  and `SourceCodePro.zip`.
- `git diff --check` after the v9 session documentation and script updates.
- `bash -n bin/docpunct features/*/*.sh tests/*.sh tests/container/*.sh` after
  adding the Double Commander Qt6 runtime dependency.
- `./bin/docpunct test-doublecmd-feature 24.04` after adding
  `libqt6printsupport6` and the Double Commander `ldd` regression check.
- `bash -n bin/docpunct features/*/*.sh tests/*.sh tests/container/*.sh` after
  reworking update dependency handling and dotfile reconciliation.
- `shellcheck bin/docpunct features/*/*.sh tests/*.sh tests/container/*.sh`
  with the host ShellCheck binary after Docker socket access blocked the
  project Docker ShellCheck target.
- `./bin/docpunct test-smoke` after adding regressions for newly introduced
  update dependencies and dotfile update backups.
- `bash -n bin/docpunct features/*/*.sh tests/*.sh tests/container/*.sh`,
  host `shellcheck`, `./bin/docpunct test-smoke`, and `git diff --check` after
  adding `wl-clipboard` and `xclip` to `debian-gui-packages`.
- `git diff --check`, `bash -n bin/docpunct features/*/*.sh tests/*.sh
  tests/container/*.sh`, host `shellcheck`, and `./bin/docpunct test-smoke`
  after updating the architecture document and resume handoff.
- `bash -n bin/docpunct features/*/*.sh tests/*.sh tests/container/*.sh`,
  host `shellcheck`, `./bin/docpunct test-smoke`, and `git diff --check`
  after moving PATH-related shell setup from `.bashrc` to `.profile`.
- `git diff --check` after updating `TODO.md` and the architecture document.
- `git diff --check` after aligning `HOWTO.md` with the `.profile` split.
- Host `shellcheck`, `./bin/docpunct test-smoke`, and
  `./bin/docpunct test-container 26.04` after adding Git Credential Manager's
  ICU runtime dependency.
- `git diff --check`, `bash -n bin/docpunct features/*/*.sh tests/*.sh
  tests/container/*.sh`, host `shellcheck`, and `./bin/docpunct test-smoke`
  after adding the already-installed install early return and failed-install
  cleanup.
- `git diff --check`, `bash -n`, host `shellcheck`, and
  `./bin/docpunct test-smoke` after replacing whole-file shell entrypoint
  symlinks with additive managed blocks and shared shell fragments.

## Pending clarification

1. `.gitconfig-private` was not imported yet because its name indicates private data, although the provided file is empty.

## Remaining work

- Decide whether to import the empty `.gitconfig-private`.
- Consider signature/checksum validation for Git Credential Manager release assets.
- Consider signature/checksum validation for Double Commander release assets.
- Consider signature/checksum validation for Nerd Fonts release assets.
- Remove the deprecated Neovim file-level symlink migration logic from
  `features/dotfiles/reconcile.sh` after existing machines have migrated.

## Known issues

- Git Credential Manager package signature validation is not implemented.
- Double Commander release asset signature/checksum validation is not implemented.
- Nerd Fonts release asset signature/checksum validation is not implemented.
- Neovim removal currently removes the user binary/runtime path but leaves the source checkout under `~/.cache/docpunct/src/neovim`.
- Neovide is installed with `cargo install --locked neovide`, not from a managed source checkout.
- The Git Credential Manager installer has been API-selector tested but not install-tested because it downloads a `.deb` and invokes `sudo dpkg`.
- APT/sudo-backed package feature scripts have been tested in disposable containers, but most have not been install-tested directly on the host.
- Third-party APT repository feature scripts other than Docker have not been install-tested on the host because they download signing keys/source configuration and invoke APT/sudo.
- `./bin/docpunct shellcheck` is blocked in the current host environment by
  Docker socket permissions; host `shellcheck` passed and is the current
  fallback.
- APT/container-heavy tests were not rerun for the `.profile` change because
  the behavior is covered by host-safe smoke tests.

## Next steps

1. Decide whether to import the empty `.gitconfig-private`.
2. Consider signature/checksum validation for Git Credential Manager,
   Double Commander, and Nerd Fonts release assets.
3. Remove the deprecated Neovim file-level symlink migration logic after
   existing machines have migrated.
