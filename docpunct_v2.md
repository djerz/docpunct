# docpunct — Specification v2

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
│   ├── debian-cli-packages/
│   ├── debian-gui-packages/
│   ├── rust/
│   ├── node/
│   ├── python-uv/
│   ├── neovim/
│   └── neovide/
├── dotfiles/
└── HOWTO.md
```

The `justfile` is a convenience layer.

All actual logic must reside in `bin/docpunct` and feature scripts.

---

## Runtime directories

`docpunct` uses cache-owned directories for state, logs, generated source checkouts, and backups:

```text
~/.cache/docpunct/state
~/.cache/docpunct/log
~/.cache/docpunct/src
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

Source repositories managed by docpunct should be stored under:

```text
~/.cache/docpunct/src
```

Examples:

```text
~/.cache/docpunct/src/neovim
~/.cache/docpunct/src/neovide
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
```

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
```

Meanings:

```text
DOCPUNCT_ROOT        Absolute path to the docpunct repository
DOCPUNCT_FEATURE     Current feature name
DOCPUNCT_FEATURE_DIR Absolute path to the current feature directory
DOCPUNCT_STATE_DIR   ~/.cache/docpunct/state
DOCPUNCT_CACHE_DIR   ~/.cache/docpunct
DOCPUNCT_LOG_DIR     ~/.cache/docpunct/log
```

Scripts should be idempotent internally where reasonable, but docpunct itself prevents normal double installation.

---

## Dependency resolution

Dependencies must be installed and updated before the feature that depends on them.

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

1. Update dependencies first.
2. Run `update.sh` if present.

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

Dotfiles are managed through symbolic links.

Example:

```text
~/.bashrc -> /path/to/docpunct/dotfiles/.bashrc
```

Installation behavior:

1. If the target does not exist, create the symlink.
2. If the target exists and is not already managed by docpunct:
   - create a one-time backup
   - replace it with a symlink
3. If already managed by docpunct:
   - leave the backup untouched
   - update the symlink if necessary

Backups are stored under:

```text
~/.cache/docpunct/backups/dotfiles
```

Removal behavior:

1. Remove the symlink.
2. Restore the original backup if one exists.

The command:

```sh
docpunct relink
```

must recreate all managed symlinks when the repository location changes.

Dotfiles must never contain hardcoded usernames.

Use:

```sh
$HOME/.local/bin
```

instead of:

```sh
/home/chris/.local/bin
```

Initial dotfiles may include:

```text
.gitconfig
.gitconfig-private
.config
.bashrc
.local/share/applications
```

The dotfile feature should support extending this list over time.

---

## Core feature

The `core` feature is a meta-feature.

Initial dependencies:

```yaml
depends:
  - dotfiles
  - debian-cli-packages
```

The feature contains no installation logic of its own.

---

## Debian CLI packages feature

Installs command-line packages required by docpunct and other features.

Initial package list:

```text
curl
build-essential
git
git-crypt
gh
```

`gh` must be installed using GitHub's official APT repository.

Removal must remove package, repository configuration, and repository signing keys owned by this feature.

---

## Debian GUI packages feature

Installs graphical applications.

Initial package list:

```text
keepassxc
brave-browser
code
google-chrome-stable
```

Packages distributed through third-party repositories must install and remove package, repository configuration, and signing keys owned by this feature.

---

## Rust feature

Rust must be installed using the official rustup installer.

Rust must not be installed from Ubuntu packages.

Default version:

```text
stable
```

Removal should remove rustup, toolchains, configuration, and cache created by rustup.

---

## Node feature

Node.js must be installed using nvm.

Node.js must not be installed from Ubuntu packages.

Default version:

```text
lts
```

Removal should remove nvm, installed Node.js versions, npm global packages, configuration, and cache owned by nvm and npm.

---

## Python uv feature

uv must be installed using Astral's standalone installer.

Default version:

```text
latest stable release
```

Removal should remove installed binaries, configuration, and cache owned by uv.

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

- source checkout
- docpunct-installed binaries and files

Removal must not remove Neovim user cache, configuration, or data files.

Do not remove:

```text
~/.config/nvim
~/.local/share/nvim
~/.cache/nvim
```

---

## Neovide feature

Neovide must be built from source.

Source repository location:

```text
~/.cache/docpunct/src/neovide
```

Update behavior:

1. Fetch tags.
2. Select the latest stable tag.
3. Rebuild and reinstall regardless of local state.

Removal should remove:

- source checkout
- docpunct-installed binaries and files
- docpunct-installed desktop entries

Removal must not remove Neovide user cache, configuration, or data files.

Do not remove:

```text
~/.config/neovide
~/.local/share/neovide
~/.cache/neovide
```

A desktop entry should be installed into:

```text
~/.local/share/applications
```

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
- dotfile backup and restore
- Debian CLI package management
- Debian GUI package management
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
