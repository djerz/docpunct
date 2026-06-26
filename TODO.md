# docpunct TODO

## Resumable status

- Framework and initial feature scaffolding have been generated.
- `../mydotfiles` was inspected.
- Safe dotfiles were imported into `dotfiles/` and listed in
  `features/dotfiles/files.txt`.
- `arch/docpunct_arch.md` is the main living docpunct architecture
  specification. Epel keeps its feature-specific architecture separately in
  `arch/epel_arch.md`.
- `HOWTO.md` has been updated to match the living architecture and implemented
  behavior.
- Dependency cycle detection has been added for install/update dependency graphs.
- `debian-cli-packages` includes `libicu-dev` so Git Credential Manager's
  bundled .NET runtime can start on fresh Ubuntu installations, including
  Ubuntu 26.04.
- `debian-cli-packages` includes `git-crypt` for repository encryption
  workflows that share the common CLI package set.
- `debian-gui-packages` contains distro-repository GUI packages plus
  `desktop-file-utils`, the GNOME Secret Service stack, `libfontconfig1-dev`,
  `libfreetype6-dev`, `wl-clipboard`, `xclip`, and `libqt6printsupport6` for
  Neovide desktop entry support, GUI credential-vault support, Neovide Cargo
  link-time requirements, Neovide clipboard integration, and the Double
  Commander Qt6 runtime.
- Third-party APT repository packages are modeled as separate features:
  `brave-browser`, `visual-studio-code`, `google-chrome`, `github-cli`, and
  `docker`.
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
  - `just test-obsidian-feature ubuntu=VERSION` runs a real official Obsidian
    Debian package install/update/remove lifecycle in a separate
    non-privileged container.
  - `just test-github-copilot-cli-feature ubuntu=VERSION` runs the standalone
    GitHub Copilot CLI install/update/remove lifecycle in a separate
    non-privileged container.
  - `just test-openai-codex-cli-feature ubuntu=VERSION` runs the official
    OpenAI Codex CLI npm install/update/remove lifecycle in a separate
    non-privileged container.
- Every `just` target now delegates to an equivalent `./bin/docpunct` command so the test suite can be run without `just`.
- `docpunct update FEATURE` requires the requested feature to be installed and
  updates only that feature. It reports dependency actions that may also be
  needed in dependency-first order without running them automatically.
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
- `session-env.sh` now exports `GPG_TTY` when `tty` reports a real terminal, so
  GPG/pass-backed Git Credential Manager prompts can use terminal pinentry.
- Git settings now live in a managed include fragment, with `.gitconfig` using
  an additive marked block so existing host Git configuration is preserved and
  takes precedence.
- The current host has completed the additive `.gitconfig` migration. Its
  global config is a regular file with one docpunct include block, and the
  managed fragment link and included Git configuration parse successfully.
- Git Credential Manager and Double Commander downloads are now verified
  against SHA-256 digests in the GitHub release API before installation or
  extraction. Nerd Fonts archives are verified against the upstream release's
  `SHA-256.txt` asset.
- `debian-mail-packages` and `epel` provide the package, CLI, queue, systemd
  user-unit, snapshot backup, and notmuch.nvim integration layers for the local
  Maildir workflow. Detailed instructions live in `features/epel/HOWTO.md`.
- `debian-mail-packages` includes `libnotmuch-dev` because notmuch.nvim loads
  the unversioned `libnotmuch.so` name, which the runtime package does not
  provide.
- Git HTTPS credentials are now opt-in: `gpg` provides instructional
  GPG/pass setup and `gcm-gpg` configures GCM with encrypted GPG storage.
  `core` and `dotfiles` do not select a credential helper.
- The GPG HOWTO also documents optional public-key publication and Git commit
  signing with the selected full key fingerprint.
- `gcm-gpg` owns an end-of-file marked include in `~/.gitconfig`, so its helper
  reset follows preserved host helpers. Configuration fails closed unless GCM
  with GPG storage is the only effective global credential helper.
- The deprecated `git-credential-manager` feature has been removed after its
  migration window; `gcm-gpg` now fully owns docpunct's Git Credential Manager
  package lifecycle and adopts stale legacy ownership markers on update.
- The resumed initial Gmail synchronization completed successfully on
  2026-06-22. `epel sync` processed all 15 folders without `OVERQUOTA`, and
  notmuch indexing completed with 67,937 indexed messages. The account had
  152,104 messages in Maildir `cur` and `new` directories after the run.
- Epel's notmuch guidance now ignores mbsync's exact `.mbsyncstate` and
  `.uidvalidity` metadata basenames, preventing harmless per-folder non-mail
  notes during indexing without excluding messages.
- Provider Sent synchronization was validated read-only on 2026-06-22 for the
  configured Gmail account. The provider Sent Maildir contained 3,277 indexed
  messages, including 3,276 from the configured sender; its newest self-sent
  message was dated 2026-06-22 19:38:28 UTC, and two provider-Sent files were
  synchronized during the completed June 22 run. The epel timer remains
  disabled pending an explicit decision to enable it.
- A manual end-to-end Gmail round trip was completed on 2026-06-22. A message
  containing `This is a test!` was sent to the configured account, received,
  replied to from notmuch.nvim with `R`, and submitted with `Ctrl-g Ctrl-g`.
  After synchronization, notmuch showed one two-message thread with both
  messages present in the provider Sent folder and INBOX; the thread carried
  the `replied` tag.
- Epel now provides `epel fsync` for a fast foreground sync of explicitly
  configured mbsync targets such as `personal@example.com:INBOX`. It uses the
  same mail lock as full sync and backup, runs `notmuch new` afterward, records
  `last-fsync` separately, and leaves `epel sync` as the unchanged
  `mbsync --all` full synchronization path.
- The current pinned notmuch.nvim send workflow leaves both its temporary send
  terminal and sent draft open. The Epel HOWTO now documents closing the
  terminal with `Ctrl-\ Ctrl-n`, then `:q`, and deleting the sent draft with
  `:bdelete` to return to the prior mail buffer.
- The current host's standalone Codex CLI installation was removed and
  replaced with the committed `openai-codex-cli` feature on 2026-06-22.
  `codex` now resolves through NVM's global `@openai/codex` package, while
  authentication, configuration, sessions, skills, and other user-owned state
  under `~/.codex` were preserved.
- Added an `ollama` feature that installs the current digest-verified official
  Linux release user-locally, manages a loopback-only systemd user service,
  preserves models on removal, and points users to its HOWTO to install a
  model. The HOWTO covers this host's CPU-only model choices, higher-end GPU
  tiers, Codex CLI, Copilot CLI, the pinned CopilotChat.nvim provider API, and
  direct HTTP clients.
- Ollama's managed service now defaults to a 65,536-token context. A live Codex
  `gpt-oss:20b` session exposed that Ollama's 4K default was consumed by 4,095
  initial instruction tokens, leaving only one output token and no visible
  answer. The HOWTO documents the default, systemd drop-in overrides, and
  expected CPU-only latency. Ollama updates explicitly restart an already
  active service after reloading its unit so changed environment settings take
  effect.
- The Ollama HOWTO now documents faster CPU-only Qwen3 experiment tiers for
  this computer class: `qwen3:8b`, `qwen3:1.7b`, and `qwen3:0.6b`. Their speed
  multipliers are explicitly presented as estimates, with the smallest model
  treated as a latency experiment rather than a dependable coding agent.
- Removed the deprecated Neovim file-level symlink migration special case from
  dotfiles reconciliation. Existing directories are now handled by the normal
  backup-and-replace path before creating the managed directory symlink.
- Added a temporary `debug-corpo-proxy` feature for diagnosing corporate proxy
  setup issues. Its current probe performs the same GitHub release API lookup
  and asset download as `gcm-gpg`, installs nothing, and writes a sanitized
  latest log at
  `~/.cache/docpunct/log/debug-corpo-proxy-latest.log`.
- Added GNOME Secret Service support packages to `debian-gui-packages` for GUI
  system-vault users such as GitHub Copilot CLI: `gnome-keyring`,
  `libpam-gnome-keyring`, `libsecret-tools`, `dbus-user-session`, and
  `seahorse`. These packages are treated as shared desktop/keyring
  infrastructure and are intentionally not removed by conservative
  `debian-gui-packages` removal.
- `docpunct relink` now runs optional relocation hooks for installed features.
  Epel uses this to repair its command, private msmtp wrapper, and systemd user
  unit links after the repository moves; unrelated symlinks remain protected.
- The earlier Secret Service package change is committed and `main` currently
  matches `origin/main`.
- The current working tree intentionally contains uncommitted repository
  relocation work: the generic feature `relink.sh` hook, Epel link repair,
  regression coverage, and corresponding architecture, HOWTO, and TODO
  updates. Preserve these changes when resuming.
- Future sessions should always run tests appropriate to the completed task:
  - shell script changes: `./bin/docpunct shellcheck` or `just shellcheck`
  - core behavior changes: `./bin/docpunct test` or `just test`
  - package/container behavior changes: the matching `test-container`,
    `test-containers`, `test-docker-feature`, or feature-specific target
- Future sessions are allowed to run any test target without asking first,
  including container tests that pull images or run APT/network work inside
  containers.
- Host Docker access is healthy: `chris` is a member of the `docker` group,
  `/var/run/docker.sock` is owned by `root:docker`, and both `docker ps` and
  `./bin/docpunct shellcheck` pass in host context. Restricted AI command
  sandboxes may map supplementary groups to `nogroup`; Docker commands from
  such a sandbox must use the approved host-context execution path.
- Future features that invoke Cargo or Rust tools must source
  `$HOME/.cargo/env` themselves before calling those tools; do not rely on
  `.profile`, `.bashrc`, the Rust feature script, or a previous child process
  to update the current feature script environment.
- Before removing APT packages owned by a feature, check whether they are
  shared desktop/system dependencies and warn before implementing removal that
  could cause APT to remove packages such as `ubuntu-desktop`,
  `ubuntu-desktop-minimal`, `gdm3`, `gnome-control-center`, or `nautilus`.

## Done

- Extended repository relocation beyond dotfiles with an optional feature
  `relink.sh` hook and added Epel relocation support for all five of its
  repository-backed links.

- Added `libnotmuch-dev` to `debian-mail-packages` so notmuch.nvim can load
  the unversioned `libnotmuch.so` name, with supported-release container
  coverage. Also isolated the GCM smoke test's cache so it remains deterministic
  when invoked through `docpunct test-smoke`.
- Added standalone `gpg` and `gcm-gpg` features, including pass/key readiness
  checks, headless pinentry instructions, a separate managed Git include, and
  an explicit migration path from the deprecated implicit GCM feature.
- Removed the deprecated `git-credential-manager` feature after its migration
  window. `gcm-gpg` remains the only feature that installs and configures Git
  Credential Manager, and it adopts stale legacy package ownership markers on
  update.
- Added temporary `debug-corpo-proxy` feature diagnostics for reproducing and
  logging GitHub release curl failures behind corporate proxies.
- Added guarded `GPG_TTY` setup to the managed shared shell environment for
  GPG/pass-backed Git Credential Manager terminal prompts.
- Fixed `gcm-gpg` include ordering so later host helpers such as `store` cannot
  remain active. Existing unmanaged GCM includes migrate to an ordered marked
  block without deleting the preserved host helper settings.
- Removed implicit GCM dependencies from `core` and `dotfiles`; the base Git
  configuration no longer chooses persistent credential storage.
- Added conservative `debian-mail-packages` and the `epel` feature, including
  instructional account configuration, desktop-keyring guidance, systemd user
  automation, FIFO queued sending, timestamped checksum-based rsync snapshots,
  and host-safe smoke coverage.
- Added a narrow local mbsync AppArmor extension for Ubuntu releases whose
  packaged profile otherwise blocks keyring-backed `PassCmd` execution.
- Added notmuch.nvim to the managed Lazy configuration with `epel sync`, HTML
  rendering through `w3m`, and a Neovim-scoped private msmtp wrapper that
  routes composition through `epel submit`.

- Changed update behavior so only the explicitly requested feature is updated;
  dependencies are reported as ordered update/install suggestions and are not
  changed automatically.
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
- Added fail-closed SHA-256 verification for Git Credential Manager, Double
  Commander, and Nerd Fonts release downloads.
- Added `AIHANDOVER.md` with a concise prompt that directs new sessions to the
  authoritative specification, usage, task, and TODO documents.
- Added `libicu-dev` to `debian-cli-packages`, made the Git Credential Manager
  installer ensure it is present for failed-install retries, and added a
  container assertion after a fresh Ubuntu 26.04 core install exposed Git
  Credential Manager's ICU runtime dependency.
- Added `git-crypt` to `debian-cli-packages` and covered it in the container
  smoke test for the shared CLI package set.

- Added Bash CLI at `bin/docpunct`.
- Added `justfile` convenience commands.
- Added feature directories and manifests for:
  - `core`
  - `dotfiles`
  - `fd-find`
  - `debian-cli-packages`
  - `debian-gui-packages`
  - `desktop-apps`
  - `rust`
  - `node`
  - `python-uv`
  - `neovim`
  - `neovide`
  - `brave-browser`
  - `visual-studio-code`
  - `google-chrome`
  - `github-cli`
  - `github-copilot-cli`
  - `devcontainer-cli`
  - `doublecmd`
  - `obsidian`
- Added install/update/remove scripts where needed.
- Added dependency resolution for install/update.
- Added conservative dependency guard for removal.
- Fixed removal guard so dependents are reported instead of exiting silently.
- Added state, log, source, download, and dotfile backup directories under `~/.cache/docpunct`.
- Added dotfile symlink install, backup, restore, and relink support.
- Imported public dotfiles from `../mydotfiles`.
- Imported `.gitconfig` with `credential.helper = manager`.
- Imported `.config/nvim/lua/plugins/copilotchat.lua` with the hardcoded Copilot Node override removed.
- Added the original Git Credential Manager installer flow, which has since
  been folded into `gcm-gpg`:
  - queries the latest GitHub release dynamically
  - selects `gcm-linux-x64-*.deb` for Debian `amd64`
  - selects `gcm-linux-arm64-*.deb` for Debian `arm64`
  - installs with `sudo dpkg -i`
  - runs `git-credential-manager configure`
- Added Neovide desktop entry template and install/remove handling in the `neovide` feature.
- Updated `HOWTO.md` to reflect the latest feature set and implemented behavior.
- Added dependency cycle detection before install/update traversal.
- Updated `debian-gui-packages/packages.txt` to install `keepassxc`, `meld`, `gnome-icon-theme`, `adwaita-icon-theme-full`, and retained `desktop-file-utils` for Neovide.
- Added third-party APT repository features for Brave Browser, Visual Studio Code, and Google Chrome. Each feature owns its package, source file, and signing key.
- Added a standalone `github-cli` feature using GitHub CLI's official APT
  repository, with a pinned official keyring checksum, architecture guards,
  and conservative removal that preserves user authentication and
  configuration.
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
- Added an `amd64` `obsidian` feature for the latest official Debian release
  package, made it a dependency of `desktop-apps`, and added fail-closed digest
  verification plus feature-specific container coverage.
- Added a standalone `github-copilot-cli` feature for GitHub's official
  `amd64` and `arm64` Linux release assets, with fail-closed digest verification
  and conservative removal that preserves `~/.copilot` state.
- Added a `devcontainer-cli` feature that installs `@devcontainers/cli` with
  the default NVM-managed Node.js version and removes only that global npm
  package.
- Added a disposable Ubuntu lifecycle test for `devcontainer-cli` covering
  install, update, package-scoped removal, and preservation of Node.js/npm.
- Added an `openai-codex-cli` feature that installs OpenAI's official
  `@openai/codex` npm package with the default NVM-managed Node.js version,
  removes only that package, and preserves user-owned `~/.codex` state.
- Added a disposable Ubuntu lifecycle test for `openai-codex-cli` covering
  install, update, package-scoped removal, preservation of Node.js/npm, and
  preservation of `~/.codex` configuration.
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
- Removed the deprecated Neovim file-level symlink migration logic from
  `features/dotfiles/reconcile.sh`.
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
- Reworked `docpunct update FEATURE` to update only the requested feature and
  report possible dependency update/install commands in dependency-first
  order.
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
- Replaced the whole-file `.gitconfig` symlink with an additive managed include,
  including legacy symlink migration, host-setting precedence, conservative
  removal, and smoke coverage.

## Imported dotfiles

- `.config/docpunct/gitconfig`
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
- removal refusal when another installed feature depends on the requested
  feature
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
- Bash syntax, full host ShellCheck, `./bin/docpunct test-smoke`, and
  `git diff --check` after removing the deprecated Neovim file-level symlink
  migration logic.
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
- `bash -n`, host `shellcheck`, `./bin/docpunct test-smoke`, and scoped
  `git diff --check` after adding release-asset SHA-256 verification. The Nerd
  Fonts smoke coverage includes rejection of an invalid checksum.
- Current upstream GitHub release metadata was checked for Git Credential
  Manager and Double Commander SHA-256 digests, and the Nerd Fonts checksum
  parser was checked against the current upstream `SHA-256.txt` format.
- `bash -n`, host `shellcheck`, scoped `git diff --check`, and
  `./bin/docpunct test-smoke` after making update dependency handling advisory.
  Smoke coverage verifies dependency-first guidance and that a missing
  dependency is not installed automatically.
- `bash -n`, host `shellcheck`, `jq` validation of the Lazy lockfile,
  `./bin/docpunct test-smoke`, and `./bin/docpunct test-container` on Ubuntu
  22.04, 24.04, and 26.04 after adding `debian-mail-packages` and `epel`.
  Ubuntu 22.04 coverage exposed and verified the explicit noninteractive
  msmtp package-install fix.
- Host Bash/ShellCheck and smoke coverage plus real Ubuntu 22.04, 24.04, and
  26.04 container installs after adding `gpg` and `gcm-gpg`. Container tests
  generate an isolated no-passphrase key, initialize pass, install the current
  verified GCM package, and assert the encrypted backend configuration.
- Host Bash/ShellCheck, `./bin/docpunct test-smoke`, `git diff --check`, and
  Ubuntu 22.04, 24.04, and 26.04 container tests after adding
  `libnotmuch-dev`. A headless Neovim FFI load of `notmuch` also passed on the
  host after updating `debian-mail-packages`.
- Validated the current host's completed additive `.gitconfig` migration:
  marker counts, include path, managed fragment link, and included global Git
  configuration all passed.
- `bash -n`, host `shellcheck`, `./tests/gcm-gpg-smoke.sh`, the complete
  `./bin/docpunct test-smoke` suite, `git diff --check`, and current-host helper
  ordering after fixing and migrating the `gcm-gpg` include.
- `bash -n`, full host `shellcheck`, `./bin/docpunct test-smoke`,
  `git diff --check`, and a real Ubuntu 24.04 container install/update/remove
  lifecycle for `github-cli`. The container verified `gh` 2.95.0, owned APT
  cleanup, and preservation of `~/.config/gh`.
- `bash -n`, full host `shellcheck`, `./bin/docpunct test-smoke`,
  `git diff --check`, and a real Ubuntu 24.04 Obsidian Debian package
  install/update/remove lifecycle. The container verified the executable,
  dependency repair, and preservation of configuration and vault data.
- `bash -n`, full host `shellcheck`, `./bin/docpunct test-smoke`,
  `git diff --check`, and a real Ubuntu 24.04 standalone GitHub Copilot CLI
  install/update/remove lifecycle. The container verified Copilot CLI 1.0.63,
  the managed binary link, and preservation of `~/.copilot`.
- `bash -n`, host `shellcheck`, Git configuration parsing,
  `./bin/docpunct test-smoke`, and `git diff --check` after replacing the
  whole-file `.gitconfig` symlink with an additive managed include. The
  project-level `./bin/docpunct test` remained blocked by the documented Docker
  socket permission issue.
- A real current-host `epel sync` completed successfully on 2026-06-22 after
  resuming the provider-limited initial Gmail synchronization. mbsync processed
  all 15 folders, and `notmuch new` completed normally.
- Bash syntax, focused host ShellCheck, `./bin/docpunct test-smoke`,
  `git diff --check`, and a live `notmuch new` after adding the mbsync metadata
  ignore guidance. The live index pass completed with `No new mail` and no
  non-mail metadata notes.
- Read-only current-host provider Sent validation on 2026-06-22. The Gmail
  provider Sent path had 3,277 indexed messages, including a self-sent message
  dated 2026-06-22 19:38:28 UTC, and the epel sync timer remained disabled.
- Manual current-host Gmail send, receive, reply, and provider-Sent round-trip
  validation on 2026-06-22. The resulting notmuch thread contained two
  messages, with both represented in INBOX and the provider Sent folder, and
  was tagged `replied`.
- Bash syntax, full host ShellCheck, focused Epel smoke coverage,
  `./bin/docpunct test-smoke`, and `git diff --check` after adding `epel
  fsync`. Smoke coverage verifies the missing-configuration guidance, explicit
  INBOX target syncing, `notmuch new`, and `last-fsync` status recording.
- Bash syntax, full host ShellCheck, `./bin/docpunct test-smoke`, CLI routing
  checks, `git diff --check`, and a real Ubuntu 24.04
  `openai-codex-cli` install/update/remove lifecycle. The container verified
  `@openai/codex` 0.141.0, the `codex` command, package-scoped removal, retained
  Node.js/npm, and preserved `~/.codex/config.toml`.
- Bash syntax, focused host ShellCheck, `./bin/docpunct test-smoke`,
  `git diff --check`, current Ollama release asset/digest inspection, and a
  generated-release Ollama install/update/remove lifecycle. The lifecycle
  verified the executable link, managed service, post-install model guidance,
  and preservation of `~/.ollama`. The Ubuntu container wrapper could not run
  because the current shell still lacks usable Docker socket group access.
- Read-only current-host validation after migrating Codex CLI to docpunct. The
  active command resolves to NVM's global `@openai/codex@0.141.0`, the
  `openai-codex-cli` state marker is installed, standalone artifacts and their
  `.bashrc` PATH block are absent, and `~/.codex` authentication,
  configuration, sessions, and skills remain present.
- Bash syntax, focused host ShellCheck, the isolated Ollama lifecycle smoke
  test, the complete host-safe smoke suite, `git diff --check`, and the Ubuntu
  24.04 Ollama container lifecycle after setting the managed service's 64K
  context default. The container asserts both the loopback binding and context
  environment setting. The current host was updated and restarted; Ollama
  loaded `gpt-oss:20b` with a 65,536-token context, and Codex returned `hello`
  successfully after processing 6,711 tokens on the CPU-only host.
- `git diff --check`, Bash syntax, direct host ShellCheck, and
  `./bin/docpunct test-smoke` after adding GNOME Secret Service support
  packages to `debian-gui-packages`. The restricted command sandbox could not
  access the Docker socket, so host ShellCheck was used for that run.
- `git diff --check`, Bash syntax, full host ShellCheck, and
  `./bin/docpunct test-smoke` after adding feature relocation hooks and Epel
  repository-move repair. The corrected command also repaired the current
  host's Epel command, wrapper, and three systemd user-unit links.
- Read-only host validation confirmed the Docker socket is `root:docker`, the
  current user has active `docker` group membership, `docker ps` succeeds, and
  the Docker-based `./bin/docpunct shellcheck` target passes.

## Remaining work

- Improve epel credential security beyond command-based `secret-tool` lookup,
  including explicit OAuth/token lifecycle support.
- Replace the notmuch.nvim private msmtp wrapper if the plugin gains a
  configurable submission command. Alternatives are an upstream contribution,
  a maintained patch/fork, or direct msmtp delivery that bypasses queued mode;
  the private wrapper is the current least-invasive option.
- Consider cron support for epel on systems without systemd user services.
- Consider a provider-independent local Sent copy instead of relying on the
  provider Sent folder being synchronized back through mbsync.
- Consider adding Thunderbird and Evolution to `debian-gui-packages`; epel
  currently documents them without installing.
- Remove the deprecated unmanaged `gcm-gpg` include migration from
  `features/gcm-gpg/git-hooks.sh` after existing machines have updated
  `gcm-gpg` and gained the ordered marked include block.
- Consider independent publisher-signature validation for Git Credential
  Manager, Double Commander, Nerd Fonts, Obsidian, and GitHub Copilot CLI
  release assets.
- Remove the temporary `debug-corpo-proxy` feature after the corporate proxy
  setup issue has been diagnosed and any permanent download behavior is fixed.
- Remove the legacy whole-file `.bashrc` and `.profile` symlink migration logic
  from `features/dotfiles/shell-hooks.sh` after existing machines have migrated
  to additive shell blocks.
- Remove the legacy whole-file `.gitconfig` symlink migration logic from
  `features/dotfiles/git-hooks.sh` after existing machines have migrated to the
  additive include block.

## Known issues

- notmuch.nvim currently hardcodes `msmtp`; epel uses a private wrapper placed
  first on Neovim's PATH so queued mode works without patching the plugin.
- Epel's v1 credential instructions use the desktop keyring through
  `secret-tool`; provider OAuth and token refresh are not automated.
- Epel can only preserve mail after it has synchronized into the local Maildir
  and reached a completed snapshot. Its default backup root may be on the same
  physical disk and therefore is not protection against disk loss.
- Independent publisher-signature validation is not implemented for Git
  Credential Manager, Double Commander, Nerd Fonts, Obsidian, or GitHub Copilot
  CLI release assets. Their SHA-256 checksums come from the same GitHub release
  trust boundary as the downloads.
- Neovim removal currently removes the user binary/runtime path but leaves the source checkout under `~/.cache/docpunct/src/neovim`.
- Neovide is installed with `cargo install --locked neovide`, not from a managed source checkout.
- APT/sudo-backed package feature scripts have been tested in disposable containers, but most have not been install-tested directly on the host.
- Third-party APT repository feature scripts other than Docker have not been install-tested on the host because they download signing keys/source configuration and invoke APT/sudo.
- Restricted command sandboxes do not expose the host's effective Docker group
  membership. Docker-backed tests must run through approved host-context
  execution; this is a sandbox boundary, not a host Docker permission defect.
- APT/container-heavy tests were not rerun for the `.profile` change because
  the behavior is covered by host-safe smoke tests.
- The documented Qwen3 speed-tier multipliers have not been benchmarked on the
  current host; actual Codex latency and reliability depend on prompt length,
  context size, quantization, and tool use.

## Next steps

1. Decide whether to enable epel's systemd sync timer now that provider Sent
   synchronization has been validated.
2. Consider independent publisher-signature validation for Git Credential
   Manager, Double Commander, Nerd Fonts, Obsidian, and GitHub Copilot CLI
   release assets.
3. Run `./bin/docpunct install debug-corpo-proxy` on the corporate proxy machine
   and inspect `~/.cache/docpunct/log/debug-corpo-proxy-latest.log`.
4. Remove the deprecated unmanaged `gcm-gpg` include migration after existing
   machines have updated to the ordered marked include block.
5. Remove the legacy whole-file `.bashrc` and `.profile` symlink migration
   logic after existing machines have migrated to additive shell blocks.
6. Remove the legacy whole-file `.gitconfig` symlink migration logic after
   existing machines have migrated to the additive include block.
