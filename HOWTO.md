# docpunct HOWTO

This document explains how to use and extend `docpunct`.

`docpunct` is a small personal bootstrap system for Ubuntu. It installs, updates, and removes features that define parts of a Linux user environment.

It is intentionally simple. It is not a package manager.

---

## First use

Clone the repository yourself:

```sh
git clone https://github.com/djerz/docpunct.git
cd docpunct
```

Run the core install:

```sh
./bin/docpunct install core
```

If you later add a `justfile`, you may also use convenience commands such as:

```sh
just install core
just update neovim
just remove neovide
```

`just` is optional. The main command is always `./bin/docpunct`.

---

## Common commands

List available features:

```sh
./bin/docpunct list
```

Show installed features:

```sh
./bin/docpunct status
```

Install a feature:

```sh
./bin/docpunct install neovim
```

Update a feature:

```sh
./bin/docpunct update neovim
```

Remove a feature:

```sh
./bin/docpunct remove neovim
```

Relink dotfiles after moving the repository:

```sh
./bin/docpunct relink
```

---

## Runtime directories

`docpunct` stores its own generated state and cache files under:

```text
~/.cache/docpunct
```

Important subdirectories:

```text
~/.cache/docpunct/state
~/.cache/docpunct/log
~/.cache/docpunct/src
~/.cache/docpunct/backups/dotfiles
```

Source repositories built by docpunct are checked out under:

```text
~/.cache/docpunct/src
```

Example:

```text
~/.cache/docpunct/src/neovim
```

---

## Dotfiles

Dotfiles are managed as symbolic links.

Example:

```text
~/.bashrc -> /path/to/docpunct/dotfiles/.bashrc
```

If a target file already exists, docpunct makes a one-time backup before replacing it with a symlink.

Backups are stored under:

```text
~/.cache/docpunct/backups/dotfiles
```

When the dotfiles feature is removed, docpunct removes the symlink and restores the backup if one exists.

If the repository moves, run:

```sh
./bin/docpunct relink
```

Dotfiles should not hardcode usernames.

Use:

```sh
$HOME/.local/bin
```

Do not use:

```sh
/home/chris/.local/bin
```

---

## Logs

By default, docpunct only creates logs when an operation fails.

Logs are written to:

```text
~/.cache/docpunct/log
```

Filename format:

```text
YYYYMMDD-HHMMSS-command-feature.log
```

Example:

```text
20260613-151422-install-neovim.log
```

If a command fails, docpunct prints the log path.

---

## State

Installed features are tracked using plain files under:

```text
~/.cache/docpunct/state/installed
```

Example:

```text
~/.cache/docpunct/state/installed/rust
~/.cache/docpunct/state/installed/neovim
```

The presence of a file means the feature is installed.

There is no database.

---

## Writing a new feature

Create a directory under `features/`.

Example:

```text
features/my-feature/
├── feature.yml
├── install.sh
├── update.sh
└── remove.sh
```

Only `feature.yml` is required.

Scripts are optional, but if present they must be executable.

Make scripts executable:

```sh
chmod +x features/my-feature/install.sh
chmod +x features/my-feature/update.sh
chmod +x features/my-feature/remove.sh
```

---

## feature.yml

The feature name is the directory name.

Do not add a `name` property to `feature.yml`.

Minimal example:

```yaml
description: Install my custom tool.

depends:
  - debian-cli-packages
```

Both `description` and `depends` are optional.

A meta-feature may only contain dependencies:

```yaml
description: My preferred desktop setup.

depends:
  - core
  - debian-gui-packages
  - neovim
  - neovide
```

---

## Feature scripts

Supported fixed script names:

```text
install.sh
update.sh
remove.sh
```

Do not declare script names in YAML.

When a script exists, docpunct runs it from the feature directory with helpful environment variables.

Available variables:

```sh
DOCPUNCT_ROOT
DOCPUNCT_FEATURE
DOCPUNCT_FEATURE_DIR
DOCPUNCT_STATE_DIR
DOCPUNCT_CACHE_DIR
DOCPUNCT_LOG_DIR
```

Example `install.sh`:

```sh
#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/.local/bin"
cp "$DOCPUNCT_FEATURE_DIR/bin/my-tool" "$HOME/.local/bin/my-tool"
```

Example `remove.sh`:

```sh
#!/usr/bin/env bash
set -euo pipefail

rm -f "$HOME/.local/bin/my-tool"
```

---

## Install, update, and remove behavior

### Install

If the feature is already installed, docpunct returns successfully and does not run the scripts again.

Example:

```text
already installed: neovim
```

If the feature is not installed, docpunct installs dependencies first, runs `install.sh` if present, and marks the feature installed only after success.

### Update

A feature must already be installed before it can be updated.

When updating, dependencies are updated first.

If update fails, docpunct keeps the feature marked as installed and does not automatically remove it.

### Remove

If the feature is not installed, docpunct returns successfully.

If another installed feature depends on the feature, docpunct refuses removal.

Removal only unmarks the feature after `remove.sh` succeeds.

---

## Writing safe remove.sh scripts

Removal should be conservative.

Remove files that clearly belong to the feature.

Avoid deleting broad user directories unless they are fully owned by the feature.

For example, the Neovim feature should remove the docpunct source checkout and installed binary, but should not remove:

```text
~/.config/nvim
~/.local/share/nvim
~/.cache/nvim
```

The Neovide feature should not remove:

```text
~/.config/neovide
~/.local/share/neovide
~/.cache/neovide
```

---

## Security and privacy rules

Never commit:

- passwords
- private keys
- access tokens
- machine-specific secrets
- personal private data

Private configuration should stay outside the repository or be managed separately.

The repository should remain safe to clone publicly.

---

## Initial features

The initial implementation should provide these features:

```text
core
dotfiles
debian-cli-packages
debian-gui-packages
rust
node
python-uv
neovim
neovide
```

`core` is a meta-feature depending on:

```text
dotfiles
debian-cli-packages
```

