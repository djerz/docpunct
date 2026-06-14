# docpunct HOWTO

This document explains how to use and extend `docpunct`.

`docpunct` is a small personal bootstrap system for Ubuntu. It installs,
updates, and removes features that define parts of a Linux user environment.

It is intentionally simple, explicit, and human-readable. It is not a general
purpose package manager.

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

The `justfile` provides convenience commands:

```sh
just bootstrap
just install core
just update neovim
just remove neovide
```

`just` is optional. The main command is always `./bin/docpunct`, and every
`just` target has an equivalent `./bin/docpunct` command.

---

## Common commands

List available features:

```sh
./bin/docpunct list
```

Show feature status:

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

`docpunct` stores generated state and cache files under:

```text
~/.cache/docpunct
```

Important subdirectories:

```text
~/.cache/docpunct/state
~/.cache/docpunct/log
~/.cache/docpunct/src
~/.cache/docpunct/downloads
~/.cache/docpunct/backups/dotfiles
```

Source repositories built by docpunct are checked out under:

```text
~/.cache/docpunct/src
```

Downloaded release assets, such as Git Credential Manager Debian packages, are
kept under:

```text
~/.cache/docpunct/downloads
```

User-installed binaries should use standard user locations such as:

```text
~/.local/bin
```

Tools with established install locations keep their defaults, such as Rust via
`rustup`, Node.js via `nvm`, and uv via its standalone installer.

---

## Initial features

The repository currently defines these features:

```text
core
dotfiles
fd-find
debian-cli-packages
debian-gui-packages
desktop-apps
brave-browser
visual-studio-code
google-chrome
docker
doublecmd
git-credential-manager
rust
node
python-uv
neovim
neovide
```

`core` is a meta-feature depending on:

```text
debian-cli-packages
git-credential-manager
dotfiles
rust
node
python-uv
```

`dotfiles` depends on `git-credential-manager` because the imported
`.gitconfig` uses:

```ini
[credential]
	helper = manager
```

---

## Feature notes

`debian-cli-packages` installs common command-line packages with APT.

`fd-find` installs Ubuntu/Debian's `fd-find` package and creates the upstream
recommended compatibility link:

```text
~/.local/bin/fd -> /usr/bin/fdfind
```

`debian-cli-packages` depends on `fd-find` so the link is available whenever
the common CLI package set is installed.

`debian-gui-packages` installs graphical packages with APT:

```text
keepassxc
meld
gnome-icon-theme
adwaita-icon-theme-full
desktop-file-utils
```

`desktop-file-utils` is included for Neovide desktop entry validation and
updates.

Third-party APT repository packages are managed by separate features, not by
`debian-gui-packages`:

```text
brave-browser
visual-studio-code
google-chrome
docker
```

`desktop-apps` is a meta-feature for GUI desktop applications. It currently
depends on:

```text
debian-gui-packages
brave-browser
visual-studio-code
google-chrome
doublecmd
```

Each third-party package feature owns its package, APT source file, and signing
key. Removing one of these features removes the package, source file, and key
owned by that feature.

Brave Browser, Visual Studio Code, and Google Chrome use upstream APT
repositories with distro-independent `stable` suites, so the same source
configuration is used on Ubuntu 22.04, 24.04, 26.04, and later supported
Ubuntu versions. Their install scripts check the local Debian architecture
before writing APT source files.

`docker` installs Docker Engine from Docker's official APT repository. Before
installing, it removes conflicting Ubuntu/distro packages when present:

```text
docker.io
docker-compose
docker-compose-v2
docker-doc
podman-docker
containerd
runc
```

It then installs:

```text
docker-ce
docker-ce-cli
containerd.io
docker-buildx-plugin
docker-compose-plugin
```

After installation, the feature adds the invoking user to the `docker` group
with `sudo usermod -aG docker USER` when the user is not already a member. A
script cannot activate that new group in the parent shell, so run this once
after installation if you want to use Docker without opening a new login
session:

```sh
newgrp docker
```

The user can be overridden when needed:

```sh
DOCPUNCT_DOCKER_USER=chris ./bin/docpunct install docker
```

Removal removes the Docker group membership only when the Docker feature added
it. Pre-existing Docker group membership is left alone. The `docker` group
itself is also left in place; removal prints a manual cleanup hint when the
group still exists.

Docker's repository is Ubuntu-codename-specific. The Docker feature uses
`UBUNTU_CODENAME` from `/etc/os-release`, so Ubuntu 22.04 uses `jammy`, Ubuntu
24.04 uses `noble`, and Ubuntu 26.04 uses `resolute`. If Docker has not yet
published a `resolute` repository, the feature falls back to `noble`. You can
override the repository suite explicitly:

```sh
DOCPUNCT_DOCKER_UBUNTU_SUITE=noble ./bin/docpunct install docker
```

`git-credential-manager` downloads the latest upstream Linux Debian package for
the local Debian architecture, stores it in `~/.cache/docpunct/downloads`,
installs it with `sudo dpkg -i`, repairs package dependencies with APT if
needed, and runs `git-credential-manager configure`.

`doublecmd` installs the latest Double Commander GitHub release from the
portable Qt6 Linux tarball for the local architecture. It extracts the app to:

```text
~/.local/share/docpunct/doublecmd
```

It links the executable at:

```text
~/.local/bin/doublecmd
```

It also writes a desktop entry to:

```text
~/.local/share/applications/doublecmd.desktop
```

Removal deletes only those docpunct-owned install paths and leaves Double
Commander user configuration/cache directories alone.

`rust` installs Rust with the official `rustup` installer.

`node` installs Node.js with `nvm`.

`python-uv` installs uv with Astral's standalone installer.

`neovim` builds Neovim from source under `~/.cache/docpunct/src/neovim`.

`neovide` installs Neovide with:

```sh
cargo install --locked neovide
```

It also generates a desktop entry from the repository template and writes it to:

```text
~/.local/share/applications/neovide.desktop
```

---

## Dotfiles

Dotfiles are managed as symbolic links.

Example:

```text
~/.bashrc -> /path/to/docpunct/dotfiles/.bashrc
```

If a target file already exists and is not already managed by docpunct,
docpunct makes a one-time backup before replacing it with a symlink.

Backups are stored under:

```text
~/.cache/docpunct/backups/dotfiles
```

When the dotfiles feature is removed, docpunct removes the symlink and restores
the backup if one exists.

If the repository moves, run:

```sh
./bin/docpunct relink
```

The imported dotfiles are:

```text
.bashrc
.gitconfig
.config/nvim/init.lua
.config/nvim/lazy-lock.json
.config/nvim/readme.txt
.config/nvim/lua/config/keymaps.lua
.config/nvim/lua/config/lazy.lua
.config/nvim/lua/plugins/copilotchat.lua
.config/nvim/lua/plugins/diffview.lua
.config/nvim/lua/plugins/hexview.lua
.config/nvim/lua/plugins/init.lua
.config/nvim/lua/plugins/telescope.lua
.config/nvim/lua/plugins/web-devicons.lua
```

Private files such as `.gitconfig-private` are not imported without an explicit
decision. The initially supplied `.gitconfig-private` was empty and was left out
because its name indicates private data.

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

Supported properties:

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

When a script exists, docpunct runs it from the feature directory with helpful
environment variables.

Available variables:

```sh
DOCPUNCT_ROOT
DOCPUNCT_FEATURES_DIR
DOCPUNCT_FEATURE
DOCPUNCT_FEATURE_DIR
DOCPUNCT_STATE_DIR
DOCPUNCT_INSTALLED_DIR
DOCPUNCT_CACHE_DIR
DOCPUNCT_LOG_DIR
DOCPUNCT_SRC_DIR
DOCPUNCT_DOTFILES_BACKUP_DIR
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

If the feature is already installed, docpunct returns successfully and does not
run the scripts again.

Example:

```text
neovim already installed
```

If the feature is not installed, docpunct installs dependencies first, runs
`install.sh` if present, and marks the feature installed only after success.

### Update

A feature must already be installed before it can be updated.

When updating, dependencies are updated first.

If update fails, docpunct keeps the feature marked as installed and does not
automatically remove it.

### Remove

If the feature is not installed, docpunct returns successfully.

If another installed feature depends on the feature, docpunct refuses removal.

Removal only unmarks the feature after `remove.sh` succeeds.

Dependencies are not automatically removed.

---

## Writing safe remove.sh scripts

Removal should be conservative.

Remove files that clearly belong to the feature.

Avoid deleting broad user directories unless they are fully owned by the
feature.

For example, the Neovim feature may remove docpunct-installed binaries and
runtime files, but it should not remove:

```text
~/.config/nvim
~/.local/share/nvim
~/.cache/nvim
```

The current Neovim removal script leaves the source checkout under
`~/.cache/docpunct/src/neovim` untouched.

The Neovide feature removes the docpunct-installed user binary and desktop
entry, but should not remove:

```text
~/.config/neovide
~/.local/share/neovide
~/.cache/neovide
```

---

## Testing

After making changes, run tests appropriate to the area touched. Shell script
changes should always be checked with ShellCheck. Behavior changes should also
run the relevant smoke or container tests.

Run ShellCheck through the Docker image:

```sh
just shellcheck
./bin/docpunct shellcheck
```

Run host-safe smoke tests. These use temporary home/cache directories and do
not run package installers:

```sh
just test-smoke
./bin/docpunct test-smoke
```

Run the default local test set:

```sh
just test
./bin/docpunct test
```

The default test set runs ShellCheck and host-safe smoke tests only.

Run disposable Ubuntu container integration tests explicitly when Docker image
pulls and APT/network work inside containers are acceptable:

```sh
just test-container ubuntu=22.04
just test-container ubuntu=24.04
just test-container ubuntu=26.04
./bin/docpunct test-container 22.04
./bin/docpunct test-container 24.04
./bin/docpunct test-container 26.04
```

Run all supported Ubuntu container tests:

```sh
just test-containers
./bin/docpunct test-containers
```

The Docker feature has a separate privileged-container test target:

```sh
just test-docker-feature ubuntu=24.04
./bin/docpunct test-docker-feature 24.04
```

This target is intentionally separate from `just test` and
`just test-containers`.

The Double Commander feature has a separate non-privileged container test
target:

```sh
just test-doublecmd-feature ubuntu=24.04
./bin/docpunct test-doublecmd-feature 24.04
```

---

## Security and privacy rules

Never commit:

- passwords
- private keys
- access tokens
- machine-specific secrets
- personal private data

Private configuration should stay outside the repository, be managed
separately, or be encrypted with dedicated tooling.

The repository should remain safe to clone publicly.
