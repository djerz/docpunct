# docpunct — Architecture

This living architecture document incorporates implementation decisions made
during the initial Codex implementation sessions through specification v11,
plus the session that
split login-shell PATH setup out of `.bashrc` into a managed `.profile` so
user-local binaries, Cargo-installed binaries, and the NVM-managed `node`
binary are available in non-interactive login Bash shells.

Version 18 adds a standalone `github-cli` feature backed by GitHub CLI's
official APT repository, with a pinned official keyring checksum, architecture
guards, conservative removal, and real Ubuntu container coverage.

Version 19 adds an `amd64` `obsidian` feature that installs the latest official
Debian release package with fail-closed GitHub digest verification and makes it
a dependency of the `desktop-apps` meta-feature.

Version 17 replaces whole-file `.gitconfig` management with an additive marked
include of a managed Git settings fragment. Existing host settings are
preserved and take precedence, while legacy docpunct-owned symlinks migrate by
restoring their saved backup when available.

Version 15 records the addition of the `debian-mail-packages` and `epel`
features. Epel owns a conservative local Maildir workflow, systemd user units,
an outgoing queue, immutable timestamped rsync snapshots, and integration with
the managed notmuch.nvim configuration. Detailed mail architecture and usage
remain in `arch/epel_arch.md` and `features/epel/HOWTO.md`.

Version 16 makes Git HTTPS credential storage explicit. `core` and `dotfiles`
no longer install a credential helper. The standalone `gpg` feature owns the
GPG/pass command-line prerequisites and instructional key setup, while
`gcm-gpg` requires an initialized user-owned pass store and configures Git
Credential Manager with encrypted GPG storage. The former
`git-credential-manager` feature remains temporarily as a deprecated migration
source for already-installed systems.

Version 11 incorporated the session that
reworked update behavior so recipe changes can be applied without a
remove/install loop, factored dotfile reconciliation into a shared script used
by both install and update, added Neovide/Neovim clipboard helper packages, and
kept Debian GUI package removal conservative for those helpers.

Version 10 incorporated the session that
made Debian GUI package removal conservative after an Ubuntu desktop removal
cascade, added a curated Nerd Fonts feature, wired Neovide to Nerd Fonts,
installed a repo-owned Neovide desktop icon, and changed Neovim dotfile
management from file-level symlinks to a directory-level `~/.config/nvim`
symlink with a deprecated migration path for existing machines. Version 10 also
records the fix for Double Commander's Qt6 portable build runtime dependency on
Ubuntu systems.

Version 14 records the session that made `docpunct update FEATURE` update only
the explicitly requested feature. Dependencies are no longer changed
automatically; docpunct reports possible update or install commands in
dependency-first order instead.

Version 13 records the session that added fail-closed SHA-256 verification for
Git Credential Manager, Double Commander, and Nerd Fonts release downloads.
GitHub release API digests are used for Git Credential Manager and Double
Commander, while Nerd Fonts archives are checked against the release's
`SHA-256.txt` asset.

Version 12 records the sessions that:

- added managed `dotfiles/.profile` and included `.profile` in
  `features/dotfiles/files.txt`
- moved login-shell PATH-related setup from `.bashrc` to `.profile`
- kept interactive shell behavior in `.bashrc`, including aliases, prompt,
  Bash completion, and NVM Bash completion
- made `.profile` add `$HOME/.local/bin`, source `$HOME/.cargo/env` when it
  exists, export `NVM_DIR`, and source `$NVM_DIR/nvm.sh` when it exists
- chose to source `nvm.sh` from `.profile` so the `node` binary follows the
  NVM-managed default version in non-interactive login Bash shells
- added a host-safe smoke regression proving `.profile` can make an
  NVM-provided `node` binary available on `PATH`

Version 11 records the sessions that:

- made `docpunct update FEATURE` fail when the requested feature is not
  installed, while installing newly introduced dependencies so recipe changes
  can be applied without a remove/install loop
- made Debian package feature updates apply the current package recipe, so
  package additions such as `wl-clipboard` and `xclip` do not require a
  remove/install loop
- split `features/dotfiles/reconcile.sh` out of `install.sh` and made both
  `install.sh` and `update.sh` call it, so newly added dotfile entries receive
  the same backup-and-link handling during update as during initial install
- added `wl-clipboard` and `xclip` to `debian-gui-packages` so
  Neovide/Neovim clipboard integration works on Wayland and X11 sessions
- kept `wl-clipboard` and `xclip` out of
  `debian-gui-packages/removable-packages.txt`, treating them as support
  packages that should not be removed by conservative GUI package removal
- fixed the Double Commander container test's ShellCheck quoting issue
- added Docker Engine as an opt-in third-party APT repository feature
- added Ubuntu-version and architecture compatibility handling for third-party
  APT repository features
- added conservative Docker group membership handling
- added a repeatable ShellCheck target and host/container test architecture
- made every `just` target callable through `./bin/docpunct`
- added a privileged Docker feature container test
- added a Double Commander latest-release feature and feature-specific
  container test
- added a `desktop-apps` meta-feature for GUI desktop applications
- split `fd-find` into its own feature so it can own the `fd -> fdfind`
  compatibility symlink
- added optional CLI package handling for packages such as `util-linux-extra`
  that are not available on every supported Ubuntu release
- made Cargo-using feature scripts source `$HOME/.cargo/env` themselves before
  invoking Cargo/Rust tools, because one child feature script cannot update the
  environment of later feature scripts
- guarded `.bashrc` Cargo initialization so shells still start before Rust is
  installed, and added nvm shell initialization for interactive sessions
- added a host-safe smoke regression proving Neovide can find Cargo through
  `$HOME/.cargo/env` during the same docpunct run
- added `libfontconfig1-dev` and `libfreetype6-dev` to
  `debian-gui-packages`, because the Cargo-built Neovide binary links against
  Fontconfig and FreeType
- added a feature-specific non-privileged Neovide container test target for
  Ubuntu 22.04, 24.04, and 26.04
- fixed dependency traversal so install, update, and cycle detection snapshot
  dependency lists before running child feature scripts; this prevents
  stdin-consuming scripts such as `apt-get` from draining the parent dependency
  stream and skipping later dependencies
- split `debian-gui-packages` removal into a dedicated removable package list,
  so shared desktop/system dependencies such as `desktop-file-utils` are
  installed but not removed by docpunct
- recorded that future APT removal changes must check for shared desktop/system
  dependencies and warn before implementing removals that could cascade into
  packages such as `ubuntu-desktop`, `ubuntu-desktop-minimal`, `gdm3`,
  `gnome-control-center`, or `nautilus`
- added a `nerdfonts` feature that installs a curated, user-local set of Nerd
  Fonts from the latest upstream release
- made `neovide` depend on `nerdfonts`
- copied `features/neovide/neovide.ico` into a user-local icon path and used it
  in the generated Neovide desktop entry
- changed Neovim dotfile management from individual file symlinks to a
  directory-level `~/.config/nvim` symlink
- added `features/dotfiles/update.sh` so `docpunct update dotfiles` can migrate
  old docpunct-owned file-level Neovim symlinks without uninstalling dotfiles
- marked that migration path as deprecated and scheduled for later removal
- added `libqt6printsupport6` to `debian-gui-packages`, because the
  Double Commander Qt6 portable build requires Qt6 runtime libraries that are
  not bundled in the upstream archive
- strengthened the Double Commander feature container test so it fails when
  `ldd` reports unresolved shared libraries for the installed binary

## Goal

`docpunct` is a small, human-readable bootstrap system for installing, updating, and removing a personal Linux environment.

The initial target platform is Ubuntu.

The repository must never contain passwords, private keys, tokens, machine-specific secrets, or personal private data.

`docpunct` must remain simple, explicit, easy to understand, and easy to modify by hand. It is not intended to become a general-purpose package manager.

---

## Design principles

- Follow the KISS principle.
- Prefer explicit behavior over complex automation.
- Prefer user-local installation whenever possible.
- Use `sudo` only when unavoidable, such as for Debian packages and APT repositories.
- Keep feature definitions human-readable.
- Store state using plain text files and directories.
- Avoid hardcoded usernames and machine-specific paths.
- Favor maintainability and transparency over clever abstractions.
- Every feature is responsible for its own installation, update, and removal logic.
- Removal must be conservative and must not delete unrelated user data.

---

## Repository layout

```text
docpunct/
├── justfile
├── bin/
│   └── docpunct
├── features/
│   ├── core/
│   ├── dotfiles/
│   ├── fd-find/
│   ├── debian-cli-packages/
│   ├── debian-mail-packages/
│   ├── debian-gui-packages/
│   ├── desktop-apps/
│   ├── brave-browser/
│   ├── visual-studio-code/
│   ├── google-chrome/
│   ├── github-cli/
│   ├── docker/
│   ├── doublecmd/
│   ├── obsidian/
│   ├── nerdfonts/
│   ├── gpg/
│   ├── gcm-gpg/
│   ├── git-credential-manager/
│   ├── rust/
│   ├── node/
│   ├── python-uv/
│   ├── neovim/
│   ├── neovide/
│   └── epel/
├── dotfiles/
├── tests/
└── HOWTO.md
```

The `justfile` is a convenience layer.

All actual logic must reside in `bin/docpunct` and feature scripts.

The `debian-mail-packages` feature installs epel's Ubuntu package dependencies,
including `libnotmuch-dev` for notmuch.nvim's unversioned `libnotmuch.so`
loader name, and deliberately leaves them installed during removal. The `epel`
feature depends on `debian-mail-packages`, `neovim`, and `dotfiles`. It
preserves mail, configuration, credentials, state, queued messages, and
snapshots during removal. Its detailed architecture and operating instructions
live in `arch/epel_arch.md` and `features/epel/HOWTO.md`.

---

## Runtime directories

`docpunct` uses cache-owned directories for state, logs, generated source checkouts, and backups:

```text
~/.cache/docpunct/state
~/.cache/docpunct/log
~/.cache/docpunct/src
~/.cache/docpunct/downloads
~/.cache/docpunct/backups/dotfiles
```

Whenever possible, installed user binaries should use standard user locations:

```text
~/.local/bin
```

Tools that already define well-established installation locations should keep their defaults.

Examples:

- Rust via `rustup`
- Node.js via `nvm`
- uv via its standalone installer
- Git Credential Manager via upstream Debian release packages

Source repositories managed by docpunct should be stored under:

```text
~/.cache/docpunct/src
```

Examples:

```text
~/.cache/docpunct/src/neovim
```

---

## Command line interface

```sh
docpunct install FEATURE...
docpunct update FEATURE...
docpunct remove FEATURE...
docpunct status
docpunct list
docpunct relink
docpunct bootstrap
docpunct shellcheck
docpunct test-smoke
docpunct test-container [22.04|24.04|26.04]
docpunct test-containers
docpunct test-doublecmd-feature [22.04|24.04|26.04]
docpunct test-obsidian-feature [22.04|24.04|26.04]
docpunct test-docker-feature [22.04|24.04|26.04]
docpunct test-neovide-feature [22.04|24.04|26.04]
docpunct test
```

Examples:

```sh
docpunct install core
docpunct update neovim
docpunct remove neovide
docpunct relink
```

The `justfile` may expose convenience commands:

```sh
just bootstrap
just install core
just update neovim
just remove neovide
just shellcheck
just test
```

Every `just` target must delegate to an equivalent `./bin/docpunct` command so
the project remains usable when `just` is not installed.

---

## Bootstrap

The user is responsible for cloning the docpunct repository manually.

`docpunct` does not bootstrap by downloading itself.

Bootstrap means preparing the local machine after the repository already exists.

The expected first-use flow is:

```sh
git clone https://github.com/djerz/docpunct.git
cd docpunct
./bin/docpunct install core
```

An optional convenience command may exist:

```sh
just bootstrap
```

If `just` is unavailable, the user must still be able to call `./bin/docpunct` directly.

`just` is not a mandatory runtime dependency.

---

## Features

A feature is represented by a directory under `features/`.

The feature name is the directory name.

Example:

```text
features/neovim/
```

The feature name is:

```text
neovim
```

The `feature.yml` file must not contain a `name` property.

Each feature may contain:

```text
feature.yml
install.sh
update.sh
remove.sh
files.txt
```

Only `feature.yml` is required.

The scripts are optional, but when present they must be executable.

Script paths are fixed and must not be declared in YAML:

```text
install.sh
update.sh
remove.sh
```

---

## Feature manifest format

`feature.yml` must stay minimal.

Supported properties:

```yaml
description: Optional human-readable description.

depends:
  - another-feature
  - some-other-feature
```

The `description` property is optional.

The `depends` property is optional.

Example feature:

```yaml
description: Build and install Neovim from the latest stable source tag.

depends:
  - debian-cli-packages
  - rust
```

Example empty or meta-feature:

```yaml
description: Base user environment.

depends:
  - dotfiles
  - debian-cli-packages
```

A feature may contain only dependencies and no scripts.

---

## Feature scripts

Feature scripts are ordinary shell scripts.

When present, they must be executable.

If a script exists but is not executable, docpunct must fail with a clear error.

Feature scripts receive the following environment variables:

```sh
DOCPUNCT_ROOT
DOCPUNCT_FEATURE
DOCPUNCT_FEATURE_DIR
DOCPUNCT_STATE_DIR
DOCPUNCT_CACHE_DIR
DOCPUNCT_LOG_DIR
DOCPUNCT_SRC_DIR
DOCPUNCT_DOTFILES_BACKUP_DIR
```

Meanings:

```text
DOCPUNCT_ROOT        Absolute path to the docpunct repository
DOCPUNCT_FEATURE     Current feature name
DOCPUNCT_FEATURE_DIR Absolute path to the current feature directory
DOCPUNCT_STATE_DIR   ~/.cache/docpunct/state
DOCPUNCT_CACHE_DIR   ~/.cache/docpunct
DOCPUNCT_LOG_DIR     ~/.cache/docpunct/log
DOCPUNCT_SRC_DIR     ~/.cache/docpunct/src
DOCPUNCT_DOTFILES_BACKUP_DIR
                      ~/.cache/docpunct/backups/dotfiles
```

Scripts should be idempotent internally where reasonable, but docpunct itself prevents normal double installation.

---

## Dependency resolution

Install resolves and installs dependencies automatically before the feature
that depends on them. Update changes only the explicitly requested feature.
Before updating it, docpunct must list dependency actions that may also be
needed in deterministic, dependency-first order, without running them.

Dependency ordering must be deterministic.

If a dependency does not exist, docpunct must fail with a clear error.

If a dependency cycle exists, docpunct must fail with a clear error.

Removing a feature must only remove the requested feature.

Dependencies must never be automatically removed during feature removal.

If another installed feature depends on the feature being removed, removal must be refused.

A future `--force` option may be added, but it is not required for the first version.

Future support for this command may be added but is not required:

```sh
docpunct autoremove
```

---

## Idempotency

### Install

If `docpunct install FEATURE` is called for an already installed feature, it must return successfully without reinstalling the feature or its dependencies.

Output example:

```text
already installed: FEATURE
```

If the feature is not installed, docpunct must:

1. Install dependencies first.
2. Run `install.sh` if present.
3. Mark the feature installed only after successful completion.

### Update

If `docpunct update FEATURE` is called for a feature that is not installed, it must fail.

If the feature is installed, docpunct must:

1. Inspect the full dependency tree without changing it.
2. Print suggested `docpunct update DEPENDENCY` commands for installed
   dependencies and `docpunct install DEPENDENCY` commands for missing
   dependencies, in dependency-first order.
3. Run `update.sh` only for the explicitly requested feature.

### Remove

If `docpunct remove FEATURE` is called for a feature that is not installed, it must return successfully.

Output example:

```text
not installed: FEATURE
```

If the feature is installed, docpunct must:

1. Refuse removal if another installed feature depends on it.
2. Run `remove.sh` if present.
3. Mark the feature as removed only after successful completion.

---

## Failure behavior

### Install failure

If installation fails, docpunct must:

1. Keep an error log.
2. Attempt to run the feature's `remove.sh` script if present.
3. Leave the feature unmarked as installed.
4. Report the error and log path.

### Update failure

If update fails, docpunct must:

1. Keep an error log.
2. Leave the existing feature state unchanged.
3. Not automatically remove the feature.
4. Report the error and log path.

Rationale: a failed update should not destroy a previously working installation.

### Remove failure

If removal fails, docpunct must:

1. Keep an error log.
2. Keep the feature marked as installed.
3. Report the error and log path.

---

## Logging

Logs are stored under:

```text
~/.cache/docpunct/log
```

By default, log files should only be created when an operation fails.

Filename format:

```text
YYYYMMDD-HHMMSS-command-feature.log
```

Examples:

```text
20260613-151422-install-neovim.log
20260613-151700-update-rust.log
```

Console output should avoid noise.

Example output:

```text
installing: rust
installed: rust
already installed: node
error: install failed: neovim
log: ~/.cache/docpunct/log/20260613-151422-install-neovim.log
```

A future debug or always-log option may be added, but is not required for the first version.

---

## State tracking

State is stored under:

```text
~/.cache/docpunct/state
```

Suggested layout:

```text
~/.cache/docpunct/state/
├── installed/
│   ├── rust
│   ├── neovim
│   └── dotfiles
└── files/
    ├── neovim
    └── neovide
```

The presence of a file under `installed/` indicates that a feature is installed.

State must remain human-readable and editable.

No database is required.

The `files/` directory may contain hand-written or generated file lists for features that benefit from file-based removal.

A feature-specific `files.txt` may also be kept in the feature directory when that is clearer.

---

## Removal model

Each feature owns its removal logic.

A feature removal script is responsible for removing files created by that feature.

Feature-specific file manifests may be used when useful.

Removal should be conservative.

Docpunct should only remove files known to belong to the feature.

Removal must avoid deleting unrelated user data.

---

## Dotfiles

Most dotfiles are managed through symbolic links. `.profile`, `.bashrc`, and
`.gitconfig` are managed additively because existing installations may already
contain configuration that docpunct must preserve.

Example file-level symlink:

```text
~/.config/docpunct/session-env.sh -> /path/to/docpunct/dotfiles/.config/docpunct/session-env.sh
~/.config/docpunct/bash-ext.sh -> /path/to/docpunct/dotfiles/.config/docpunct/bash-ext.sh
```

Neovim configuration is managed as a directory-level symlink:

```text
~/.config/nvim -> /path/to/docpunct/dotfiles/.config/nvim
```

This keeps Neovim, Telescope, language servers, and plugin tooling looking at a
single coherent configuration tree. The imported Telescope `<leader>fn` mapping
also searches Neovim config with `follow = true`, `hidden = true`, and
`no_ignore = true`.

Installation behavior:

1. If the target does not exist, create the symlink.
2. If a target file exists and is not already managed by docpunct:
   - create a one-time backup
   - replace it with a symlink
3. If already managed by docpunct:
   - leave the backup untouched
   - update the symlink if necessary
4. If `~/.config/nvim` exists as an old file-level docpunct symlink layout:
   - replace it with the directory-level symlink only when it contains only
     docpunct-owned symlinks and directories
   - refuse the migration when local files or non-docpunct symlinks are present
5. Reconcile shell entrypoints separately:
   - insert one canonical marked block near the top of `.profile` that sources
     `~/.config/docpunct/session-env.sh`
   - insert one canonical marked block near the top of `.bashrc` that sources
     `~/.config/docpunct/bash-ext.sh`
   - preserve all content outside those blocks
   - refuse foreign entrypoint symlinks and malformed or duplicate markers
6. When migrating old docpunct-owned whole-file `.profile` or `.bashrc`
   symlinks, restore the saved original when available before inserting the
   marked block. Create a minimal regular entrypoint when no backup exists.
7. Reconcile Git configuration separately:
   - link the tracked settings as `~/.config/docpunct/gitconfig`
   - insert one canonical marked include block near the top of `.gitconfig`
   - preserve all content outside the block, with later host settings taking
     precedence over the included docpunct defaults
   - refuse foreign `.gitconfig` symlinks and malformed or duplicate markers
8. When migrating an old docpunct-owned whole-file `.gitconfig` symlink,
   restore the saved original when available before inserting the include
   block. Create a minimal regular `.gitconfig` when no backup exists.

Backups are stored under:

```text
~/.cache/docpunct/backups/dotfiles
```

Removal behavior:

1. Remove the symlink.
2. Restore the original backup if one exists.
3. Remove only docpunct's marked blocks from `.profile`, `.bashrc`, and
   `.gitconfig`; do not remove the regular files or other content.

The command:

```sh
docpunct relink
```

must recreate all managed symlinks when the repository location changes.

The command:

```sh
docpunct update dotfiles
```

must also run the dotfiles install/relink logic. This allows existing machines
to migrate from the old Neovim file-level symlink layout without uninstalling
`dotfiles` or its dependents. The old Neovim file-level migration logic is
deprecated and should be removed after existing machines have migrated.

Dotfiles must never contain hardcoded usernames.

Use:

```sh
$HOME/.local/bin
```

instead of:

```sh
/home/chris/.local/bin
```

The managed shell fragments keep login and interactive shell setup separate:

- `session-env.sh` owns shared environment such as `PATH`, Cargo env loading,
  `NVM_DIR`, and `nvm.sh` loading for `node` availability.
- `bash-ext.sh` sources `session-env.sh`, then owns personal interactive Bash
  aliases and NVM Bash completion.
- Existing `.profile` and `.bashrc` files retain ownership of all other host
  behavior, including prompt, history, terminal setup, and system completion.

Toolchain initializers must be safe before the corresponding tool is installed.
For example, Cargo env loading in `session-env.sh` must be guarded:

```sh
[ -s "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
```

Feature scripts must not rely on `.profile` or `.bashrc` for non-interactive
installs.

Managed dotfiles may include:

```text
.config/docpunct/gitconfig
.config/docpunct/session-env.sh
.config/docpunct/bash-ext.sh
.config/nvim
```

The dotfile feature should support extending this list over time.

The managed dotfiles are:

```text
.config/docpunct/gitconfig
.config/docpunct/session-env.sh
.config/docpunct/bash-ext.sh
.config/nvim
```

The imported Git settings fragment must not select a credential helper. It
includes an optional feature-owned fragment instead:

```ini
[include]
    path = ~/.config/docpunct/git-credential-manager.gitconfig
```

Docpunct adds the settings fragment to `~/.gitconfig` through this marked block
near the top of the file, so existing settings later in the file override the
docpunct defaults:

```ini
# >>> docpunct git setup >>>
[include]
    path = ~/.config/docpunct/gitconfig
# <<< docpunct git setup <<<
```

Private files such as `.gitconfig-private` must not be imported without an
explicit decision. The initially supplied `.gitconfig-private` was empty and
was left out because its name indicates private data.

Machine-specific paths must be removed when safe. The initial Neovim Copilot
configuration had a hardcoded Node path and the override was removed.

The managed `session-env.sh` initializes user-local PATH and shell toolchain
environment:

```sh
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) PATH="$HOME/.local/bin:$PATH" ;;
esac
export PATH

[ -s "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
```

The managed `bash-ext.sh` initializes personal aliases and interactive shell
integrations such as NVM Bash completion:

```sh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
```

---

## Core feature

The `core` feature is a meta-feature.

Initial dependencies:

```yaml
depends:
  - debian-cli-packages
  - dotfiles
  - rust
  - node
  - python-uv
```

The feature contains no installation logic of its own.

---

## Debian CLI packages feature

Installs command-line packages required by docpunct and other features.

Dependencies:

```yaml
depends:
  - fd-find
```

Initial package list:

```text
build-essential
ca-certificates
cmake
curl
gettext
git
htop
jq
ninja-build
pkg-config
ripgrep
shellcheck
tmux
unzip
zip
zsh
```

`fd-find` is managed as a separate feature because Ubuntu and Debian install
the executable as `fdfind`. The feature installs the package and creates:

```text
~/.local/bin/fd -> /usr/bin/fdfind
```

The `fd-find` feature owns that symlink. Removal must delete the symlink only
when it points to `fdfind`; non-symlink `fd` files must be left untouched.

Optional packages are installed when available for the Ubuntu release:

```text
util-linux-extra
```

Removal should remove only packages from the required and optional package
lists that are currently installed.

---

## GPG and Git Credential Manager features

The `gpg` feature installs `gnupg`, `pass`, and `pinentry-curses`. It is
instructional: installation succeeds without a key, while key identity,
expiration, passphrase, export, backup, revocation, and `pass init` remain
explicit user actions documented in `features/gpg/HOWTO.md`. Removal preserves
packages, keys, agent configuration, and password-store data.

`gcm-gpg` depends on `gpg`. Before any download or Git configuration it
requires a non-empty pass `.gpg-id` whose recipients resolve to
encryption-capable secret keys. An incomplete setup fails with the GPG HOWTO
path and can be retried after initialization.

Installation behavior:

1. Query the latest release from:

   ```text
   https://api.github.com/repos/git-ecosystem/git-credential-manager/releases/latest
   ```

2. Select the Debian package asset for the local Debian architecture:

   ```text
   amd64 -> gcm-linux-x64-*.deb
   arm64 -> gcm-linux-arm64-*.deb
   ```

3. Download the selected package under:

   ```text
   ~/.cache/docpunct/downloads
   ```

4. Install it with:

   ```sh
   sudo dpkg -i PACKAGE
   ```

5. If dependency repair is required, run:

   ```sh
   sudo apt-get install -f -y
   ```

6. Write `~/.config/docpunct/git-credential-manager.gitconfig`, resetting prior
   helpers and selecting the installed GCM executable plus:

   ```ini
   [credential]
       credentialStore = gpg
   ```

7. Remove the deprecated unmanaged include written by earlier `gcm-gpg`
   versions and append an owned marked include block at the end of
   `~/.gitconfig`. Its ordering makes the managed empty helper reset occur
   after preserved host helpers such as `store`.
8. Fail closed unless applying Git's empty-helper reset semantics leaves the
   installed GCM executable as the only effective global helper, with
   `credentialStore = gpg`.

Update behavior should repeat the latest-release installation flow.

Removal deletes only the marked include block, managed fragment, and a GCM
package originally installed by `gcm-gpg`. It preserves pre-existing packages,
GPG keys, pass data, and host Git settings; preserved host credential helpers
become active again. It refuses removal while the legacy feature marker remains
so migration ordering stays explicit.

The downloaded package is verified against the SHA-256 digest in GitHub's
release API before installation. This detects a corrupted or mismatched
download but is not independent publisher-signature verification.

The legacy `git-credential-manager` feature remains for one migration window.
It emits a deprecation notice. `gcm-gpg` adopts its installed package; removing
the legacy feature afterward preserves the package when `gcm-gpg` is marked
installed. Existing users migrate in this order:

```text
install gpg -> initialize key/pass -> install gcm-gpg
-> remove git-credential-manager -> update dotfiles
```

---

## Debian GUI packages feature

Installs graphical applications.

Initial package list:

```text
keepassxc
meld
gnome-icon-theme
adwaita-icon-theme-full
desktop-file-utils
libfontconfig1-dev
libfreetype6-dev
wl-clipboard
xclip
libqt6printsupport6
```

`desktop-file-utils` is included because the Neovide feature validates and
updates the installed desktop entry when those tools are available.

Neovide's Cargo build also requires native development libraries at link time:

```text
libfontconfig1-dev
libfreetype6-dev
```

Neovide/Neovim clipboard integration requires clipboard helper packages:

```text
wl-clipboard
xclip
```

Double Commander's Qt6 portable build requires Qt6 runtime libraries from the
system. `libqt6printsupport6` is installed because APT pulls in the matching
Qt6 Core, GUI, and Widgets libraries as dependencies.

Removal must be more conservative than installation. The feature may install
shared desktop/system dependencies, but removal must only remove packages listed
in a dedicated removable package list. The initial removable list is:

```text
keepassxc
meld
```

Shared dependencies such as `desktop-file-utils`, icon themes, development
libraries, and Qt runtime libraries must not be removed by
`debian-gui-packages`, because removing them can cause APT to remove Ubuntu
desktop packages that depend on them.

Before adding or changing APT package removal behavior, check whether the
package is a shared desktop/system dependency and warn before implementing
removal that could cascade into packages such as:

```text
ubuntu-desktop
ubuntu-desktop-minimal
gdm3
gnome-control-center
nautilus
```

Third-party APT repository packages are managed by separate features rather
than by `debian-gui-packages`. Each third-party package feature owns its package
install/removal, APT source file, and signing key.

Initial third-party APT package features:

```text
brave-browser
visual-studio-code
google-chrome
github-cli
docker
```

## Desktop apps meta-feature

The `desktop-apps` feature is a meta-feature intended to collect GUI desktop
application features.

Initial dependencies:

```yaml
depends:
  - debian-gui-packages
  - brave-browser
  - visual-studio-code
  - google-chrome
  - doublecmd
  - obsidian
```

The feature contains no installation logic of its own.

## Nerd Fonts feature

The `nerdfonts` feature installs a curated set of Nerd Fonts user-locally.

The feature depends on `debian-cli-packages` for tools such as `curl`, `jq`,
and `unzip`.

Fonts are installed under:

```text
~/.local/share/fonts/docpunct/nerdfonts
```

Downloaded release archives are kept under:

```text
~/.cache/docpunct/downloads/nerdfonts
```

The curated release asset list is stored in:

```text
features/nerdfonts/fonts.txt
```

The initial curated list is:

```text
JetBrainsMono.zip
Hack.zip
FiraCode.zip
SourceCodePro.zip
Noto.zip
```

`SourceCodePro.zip` provides SauceCodePro NF, and `Noto.zip` provides Noto
Mono Nerd Font assets.

Install behavior:

1. Query the latest upstream Nerd Fonts GitHub release.
2. Download each configured archive.
3. Extract `.ttf` and `.otf` files into a staging directory.
4. Replace only the docpunct-owned install directory.
5. Run `fc-cache -f "$HOME/.local/share/fonts"` when `fc-cache` is available.

The feature must not require a system package solely for `fc-cache`; if
`fc-cache` is unavailable, it should warn that fonts may require a new session
before use.

Removal must delete only:

```text
~/.local/share/fonts/docpunct/nerdfonts
```

Each Nerd Fonts archive is verified against the release's `SHA-256.txt` asset
before extraction. This detects a corrupted or mismatched download but is not
independent publisher-signature verification.

The `brave-browser` feature installs the `brave-browser` package from Brave's
official APT repository and owns:

```text
/etc/apt/sources.list.d/brave-browser-release.sources
/usr/share/keyrings/brave-browser-archive-keyring.gpg
```

The Brave APT repository uses a distro-independent `stable` suite and supports
the `amd64` and `arm64` Debian architectures.

The `visual-studio-code` feature installs the `code` package from Microsoft's
official APT repository and owns:

```text
/etc/apt/sources.list.d/vscode.sources
/usr/share/keyrings/microsoft.gpg
```

The Visual Studio Code APT repository uses a distro-independent `stable` suite
and supports the `amd64`, `arm64`, and `armhf` Debian architectures.

The `google-chrome` feature installs the `google-chrome-stable` package from
Google's official APT repository and owns:

```text
/etc/apt/sources.list.d/google-chrome.sources
/usr/share/keyrings/google-linux-signing-key.gpg
```

The Google Chrome APT repository uses a distro-independent `stable` suite and
supports the `amd64` Debian architecture.

The `github-cli` feature installs the `gh` package from GitHub CLI's official
APT repository and owns:

```text
/etc/apt/sources.list.d/github-cli.list
/etc/apt/keyrings/githubcli-archive-keyring.gpg
```

The repository uses a distro-independent `stable` suite and publishes `i386`,
`amd64`, `armhf`, and `arm64`. The downloaded keyring must match the SHA-256
published in GitHub CLI's official installation documentation before
installation. Removal preserves user authentication and configuration under
`~/.config/gh`.

The `docker` feature installs Docker Engine from Docker's official APT
repository. Before installing, it removes conflicting Ubuntu/distro packages
when present:

```text
docker.io
docker-compose
docker-compose-v2
docker-doc
podman-docker
containerd
runc
```

It installs:

```text
docker-ce
docker-ce-cli
containerd.io
docker-buildx-plugin
docker-compose-plugin
```

After package installation, the feature adds the target user to the `docker`
group with:

```sh
sudo usermod -aG docker USER
```

The target user defaults to `DOCPUNCT_DOCKER_USER`. If that variable is unset,
use `SUDO_USER` only when it is non-empty and not `root`; otherwise use `USER`.
This avoids incorrectly targeting `root` when scripts are run under
`sudo -u USER`.

If the feature adds the user to the `docker` group, it must write a state
marker under `DOCPUNCT_STATE_DIR`. Removal should remove Docker group
membership only when that state marker exists. Pre-existing Docker group
membership must be left alone. The `docker` group itself must be left in place.
Docker packages may create or leave the `docker` group. If the group still
exists after package removal, the removal script should print a manual cleanup
hint:

```sh
sudo groupdel docker
```

The install script must not run `newgrp docker`, because it would start a child
shell and cannot update the caller's parent shell. Instead, it should print an
instruction to run:

```sh
newgrp docker
```

The feature owns:

```text
/etc/apt/sources.list.d/docker.sources
/etc/apt/keyrings/docker.asc
```

Docker's APT repository is Ubuntu-codename-specific. The feature uses
`UBUNTU_CODENAME` from `/etc/os-release` by default:

```text
Ubuntu 22.04 -> jammy
Ubuntu 24.04 -> noble
Ubuntu 26.04 -> resolute
```

If Docker has not yet published a `resolute` repository, the feature falls back
to `noble`. The suite can be overridden with:

```sh
DOCPUNCT_DOCKER_UBUNTU_SUITE=noble ./bin/docpunct install docker
```

---

## Double Commander feature

The `doublecmd` feature installs the latest Double Commander release from the
upstream GitHub project:

```text
https://github.com/doublecmd/doublecmd
```

Installation behavior:

1. Query the latest release from:

   ```text
   https://api.github.com/repos/doublecmd/doublecmd/releases/latest
   ```

2. Select the Qt6 portable Linux tarball for the local Debian architecture:

   ```text
   amd64 -> doublecmd-VERSION.qt6.x86_64.tar.xz
   arm64 -> doublecmd-VERSION.qt6.aarch64.tar.xz
   ```

3. Download the selected archive under:

   ```text
   ~/.cache/docpunct/downloads
   ```

4. Extract it to:

   ```text
   ~/.local/share/docpunct/doublecmd
   ```

5. Link the executable at:

   ```text
   ~/.local/bin/doublecmd
   ```

6. Write a desktop entry at:

   ```text
   ~/.local/share/applications/doublecmd.desktop
   ```

Dependencies:

```yaml
depends:
  - debian-cli-packages
  - debian-gui-packages
```

The upstream Qt6 portable archive is not fully self-contained on Ubuntu. The
feature relies on `debian-gui-packages` to install `libqt6printsupport6`, which
pulls in the required Qt6 runtime libraries such as Qt6 Core, GUI, Widgets, and
PrintSupport. The Double Commander feature-specific container test must check
the installed binary with `ldd` and fail if any shared library is reported as
`not found`.

Update behavior should repeat the latest-release installation flow.

Removal should remove only docpunct-owned install paths:

- `~/.local/share/docpunct/doublecmd`
- `~/.local/bin/doublecmd` when it points at the docpunct install
- `~/.local/share/applications/doublecmd.desktop`

Removal must not remove Double Commander user cache, configuration, or data
files.

The downloaded archive is verified against the SHA-256 digest in GitHub's
release API before extraction. This detects a corrupted or mismatched download
but is not independent publisher-signature verification.

---

## Obsidian feature

The `obsidian` feature installs the latest official Obsidian Debian package
from `obsidianmd/obsidian-releases`. The upstream release currently provides a
Debian package only for `amd64`; unsupported architectures fail before any
download or package change.

Installation queries the latest GitHub release, selects
`obsidian_VERSION_amd64.deb`, requires its API-provided SHA-256 digest, verifies
the downloaded package, and installs it with `dpkg`. APT repairs and installs
package dependencies when needed. Downloads are cached under
`~/.cache/docpunct/downloads`.

Update repeats the latest-release flow. Removal removes only the `obsidian`
package and preserves Obsidian configuration, caches, plugins, and vault data.
The GitHub API digest detects a corrupted or mismatched package but is not
independent publisher-signature verification.

---

## Rust feature

Rust must be installed using the official rustup installer.

Rust must not be installed from Ubuntu packages.

Default version:

```text
stable
```

Removal should remove rustup, toolchains, configuration, and cache created by rustup.

Rust feature scripts should source `$HOME/.cargo/env` when it exists before
calling Rust tools such as `rustup`. This keeps update/install behavior working
when docpunct is run from a shell that has not loaded Rust's environment yet.

---

## Node feature

Node.js must be installed using nvm.

Node.js must not be installed from Ubuntu packages.

Default version:

```text
lts
```

Removal should be conservative. The current initial implementation does not
delete `~/.nvm`; it prints a manual removal note instead.

---

## Python uv feature

uv must be installed using Astral's standalone installer.

Default version:

```text
latest stable release
```

Removal should remove installed `uv` and `uvx` binaries. Configuration and
cache removal may be added later if it can be done conservatively.

---

## Neovim feature

Neovim must be built from source.

Source repository location:

```text
~/.cache/docpunct/src/neovim
```

Update behavior:

1. Fetch tags.
2. Select the latest stable tag.
3. Rebuild and reinstall regardless of local state.

Removal should remove:

- docpunct-installed binaries and files

Removal must not remove Neovim user cache, configuration, or data files.

Do not remove:

```text
~/.config/nvim
~/.local/share/nvim
~/.cache/nvim
```

The current initial implementation leaves the source checkout under
`~/.cache/docpunct/src/neovim` untouched during removal.

---

## Neovide feature

Neovide is installed with Cargo:

```sh
cargo install --locked neovide
```

Before calling `cargo`, the Neovide feature must source `$HOME/.cargo/env` when
that file exists. This is required because installing the `rust` dependency in
the same docpunct run does not update the parent `docpunct` process or later
feature script environments.

The same rule applies to future features that invoke Cargo or Rust tools:
source `$HOME/.cargo/env` in the feature script itself and do not rely on
`.bashrc`, the Rust feature script, or a previous child process.

Dependencies:

```yaml
depends:
  - debian-gui-packages
  - nerdfonts
  - rust
  - neovim
```

Update behavior should rerun the install logic.

Removal should remove:

- the docpunct-installed user binary
- docpunct-installed desktop entries
- the docpunct-installed user-local desktop icon

Removal must not remove Neovide user cache, configuration, or data files.

Do not remove:

```text
~/.config/neovide
~/.local/share/neovide
~/.cache/neovide
```

A desktop entry should be installed into:

```text
~/.local/share/applications/neovide.desktop
```

The desktop entry should be generated from a repo template so the repository
does not hardcode a username or home directory.

The feature owns a checked-in icon:

```text
features/neovide/neovide.ico
```

Install behavior must copy that icon into a user-local path:

```text
~/.local/share/icons/docpunct/neovide.ico
```

The generated desktop entry must reference that copied icon path. Removal must
remove only the copied icon and may remove the empty docpunct icon directory
when possible.

---

## Testing

The repository provides repeatable development test targets.

Shell scripts should be checked with:

```sh
./bin/docpunct shellcheck
just shellcheck
```

`shellcheck` runs through:

```text
ghcr.io/djerz/shellcheck:latest
```

The default local test set is:

```sh
./bin/docpunct test
just test
```

It runs ShellCheck and host-safe smoke tests. Host-safe smoke tests must use
temporary home/cache directories and must not run package installers against the
host.

Host-safe smoke tests include a regression that runs the Neovide install script
with a fake Cargo binary exposed only through `$HOME/.cargo/env`. This verifies
that Neovide and future Cargo-using features do not depend on `.profile`,
`.bashrc`, or a new shell session for Cargo availability.

Host-safe smoke tests also include a regression that sources `.profile` with a
fake NVM installation and verifies that `node` is available through `PATH`.

Disposable Ubuntu container integration tests are explicit:

```sh
./bin/docpunct test-container 22.04
./bin/docpunct test-container 24.04
./bin/docpunct test-container 26.04
./bin/docpunct test-containers
```

Container tests may pull Ubuntu images and run APT/network work inside
containers. Future sessions are allowed to run any test target without asking
first.

Feature-specific container tests:

```sh
./bin/docpunct test-doublecmd-feature 24.04
./bin/docpunct test-docker-feature 24.04
./bin/docpunct test-neovide-feature 24.04
./bin/docpunct test-obsidian-feature 24.04
```

The Docker feature test runs in a privileged container. It must verify Docker
installation, Docker Compose availability, user membership addition/removal for
the `docker` group, marker cleanup, and that the `docker` group itself remains
after feature removal.

The Double Commander feature test runs in a non-privileged container. It must
verify install, update, expected executable/link/desktop-entry paths, and
removal of docpunct-owned paths.

The Neovide feature test runs in a non-privileged container. It must verify
that the real Neovide feature installation can build and link the Cargo binary,
write the desktop entry, report a version, and remove docpunct-owned paths.

---

## Security and privacy

The repository must never contain:

- passwords
- private keys
- access tokens
- machine-specific secrets
- personal private information

Private configuration should either:

- remain outside the repository
- be managed separately
- be encrypted using dedicated tooling

The repository must remain safe to clone publicly.

---

## Documentation

The repository must contain a user-facing `HOWTO.md` file.

`HOWTO.md` must explain:

- what docpunct is
- how to clone the repository
- how to run the first install
- common commands
- how dotfiles work
- how state works
- how logs work
- how to write a new feature
- how to write `install.sh`, `update.sh`, and `remove.sh`
- how to safely remove a feature
- security and privacy rules

The main repository `README.md` does not need to contain full user documentation.

---

## Initial feature set

The first implementation must support:

- feature discovery
- dependency resolution
- install
- update
- remove
- list
- status
- relink
- bootstrap
- ShellCheck
- host-safe smoke tests
- disposable Ubuntu 22.04, 24.04, and 26.04 container tests
- feature-specific Docker and Double Commander container tests
- dotfile backup and restore
- Debian CLI package management
- Debian GUI package management
- third-party APT repository package management for Brave Browser, Visual Studio Code, Google Chrome, GitHub CLI, and Docker
- `fd-find` with `~/.local/bin/fd -> /usr/bin/fdfind`
- desktop app meta-feature grouping
- Double Commander latest-release installation
- Git Credential Manager
- Rust
- Node.js
- uv
- Neovim
- Neovide
- user-facing `HOWTO.md`

The first implementation does not need:

- autoremove
- rollback support
- transaction support
- parallel execution
- remote feature repositories
- support for distributions other than Ubuntu
- package-manager-level file ownership tracking
