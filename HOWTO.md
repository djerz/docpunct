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

Relink repository-backed files after moving the repository:

```sh
./bin/docpunct relink
```

This always reconciles managed dotfiles and runs `relink.sh` for installed
features that provide that optional hook. Epel uses the hook to update its
command, private msmtp wrapper, and systemd user-unit links after a repository
move.

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
debian-mail-packages
debian-gui-packages
desktop-apps
brave-browser
visual-studio-code
google-chrome
github-cli
github-copilot-cli
devcontainer-cli
openai-codex-cli
ollama
docker
doublecmd
obsidian
gpg
gcm-gpg
debug-corpo-proxy
nerdfonts
rust
node
python-uv
neovim
neovide
epel
```

`core` is a meta-feature depending on:

```text
debian-cli-packages
dotfiles
rust
node
python-uv
```

`core` and `dotfiles` deliberately do not select a Git credential helper.
Encrypted HTTPS credential storage is available as the explicit `gcm-gpg`
feature. The tracked Git settings fragment only includes its optional managed
credential fragment:

```ini
[include]
    path = ~/.config/docpunct/git-credential-manager.gitconfig
```

`debug-corpo-proxy` is a temporary diagnostic feature for corporate proxy
failures. Its current probe reproduces the Git Credential Manager GitHub
release metadata and asset download flow without installing anything, then
writes a sanitized curl/proxy log to
`~/.cache/docpunct/log/debug-corpo-proxy-latest.log`.

---

## Feature notes

`debian-cli-packages` installs common command-line packages with APT.

It includes `libicu-dev` so the bundled .NET runtime in Git Credential Manager
has the release-specific ICU runtime it needs. Using the unversioned development
package keeps this dependency portable across supported Ubuntu releases.
The Git Credential Manager installer also checks this package directly so a
retry repairs systems where an earlier installation failed before ICU was
added to the package recipe.
It also includes `git-crypt` for repositories that rely on shared command-line
encryption tooling.

`fd-find` installs Ubuntu/Debian's `fd-find` package and creates the upstream
recommended compatibility link:

```text
~/.local/bin/fd -> /usr/bin/fdfind
```

`debian-cli-packages` depends on `fd-find` so the link is available whenever
the common CLI package set is installed.

`debian-mail-packages` installs `isync`, `notmuch`, `libnotmuch-dev`, `msmtp`,
`rsync`, `libsecret-tools`, `util-linux`, and `w3m` for the epel mail workflow.
The development package supplies the unversioned `libnotmuch.so` loader name
required by notmuch.nvim. Removal is intentionally conservative and leaves
these packages installed.

`epel` provides local Maildir synchronization, indexing, sending, queue,
backup, and systemd user-service commands. Detailed configuration and
operations are documented separately in `features/epel/HOWTO.md`.

`ollama` installs a verified official Linux runtime user-locally and manages a
loopback-only per-user service. It deliberately installs no models or GPU
drivers. Model selection, Codex CLI, Copilot CLI, CopilotChat.nvim, and direct
API examples are documented in `features/ollama/HOWTO.md`. The managed service
uses a 65,536-token context by default so coding-agent instructions do not
consume Ollama's smaller default context before a response can be generated.

`debian-gui-packages` installs graphical packages with APT:

```text
keepassxc
meld
gnome-icon-theme
adwaita-icon-theme-full
gnome-calendar
gnome-contacts
seahorse
gnome-keyring
libpam-gnome-keyring
libsecret-tools
dbus-user-session
desktop-file-utils
libfontconfig1-dev
libfreetype6-dev
wl-clipboard
xclip
libqt6printsupport6
```

Only leaf applications listed in `removable-packages.txt` are removed by the
`debian-gui-packages` remove script. Shared desktop dependencies such as
`desktop-file-utils`, icon themes, and development libraries are installed when
needed but are not removed by docpunct, because removing them can cause APT to
remove Ubuntu desktop packages that depend on them.

`desktop-file-utils` is included for Neovide desktop entry validation and
updates.

`gnome-keyring`, `libpam-gnome-keyring`, `libsecret-tools`,
`dbus-user-session`, and `seahorse` provide a GNOME-compatible Secret Service
stack and inspection tool for applications that use the system credential
store, such as GitHub Copilot CLI.

`libfontconfig1-dev` and `libfreetype6-dev` are included because the Neovide
Cargo build links against Fontconfig and FreeType.

`wl-clipboard` and `xclip` are included so Neovide/Neovim clipboard integration
works on Wayland and X11 sessions.

`libqt6printsupport6` is included because the Double Commander Qt6 portable
build needs Qt6 runtime libraries from the system. APT pulls in the matching
Qt6 core, GUI, and widgets libraries as dependencies.

`nerdfonts` installs a curated set of Nerd Fonts user-locally under:

```text
~/.local/share/fonts/docpunct/nerdfonts
```

The curated set is defined in `features/nerdfonts/fonts.txt` and currently
includes JetBrainsMono, Hack, FiraCode Nerd Font, SauceCodePro NF, and Noto
Mono. The feature downloads matching archives from the latest upstream Nerd
Fonts GitHub release, verifies them against that release's `SHA-256.txt`, and
refreshes the user font cache when `fc-cache` is available. Removing the
feature deletes only the docpunct-owned font directory.

Third-party APT repository packages are managed by separate features, not by
`debian-gui-packages`:

```text
brave-browser
visual-studio-code
google-chrome
github-cli
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
obsidian
```

Each third-party package feature owns its package, APT source file, and signing
key. Removing one of these features removes the package, source file, and key
owned by that feature.

`github-cli` installs the `gh` package from GitHub CLI's official APT
repository. It supports `i386`, `amd64`, `armhf`, and `arm64`. Removal
preserves user authentication and configuration under `~/.config/gh`. The
downloaded archive keyring is checked against the SHA-256 published in GitHub
CLI's official installation documentation before it is installed.

`github-copilot-cli` installs GitHub's latest standalone `copilot` binary for
`amd64` or `arm64` under `~/.local/share/docpunct/github-copilot-cli` and links
it from `~/.local/bin`. Release downloads require a valid GitHub API SHA-256
digest. The feature refuses to overwrite a foreign `copilot` path and preserves
`~/.copilot` authentication, configuration, and sessions during removal.

An eligible GitHub Copilot subscription is required. Start `copilot` and use
`/login`, or provide a user-owned `GH_TOKEN` or `GITHUB_TOKEN`; docpunct never
creates or stores the credential.

`devcontainer-cli` installs the `@devcontainers/cli` npm package globally for
the default NVM-managed Node.js version. Its scripts load NVM explicitly, so
installation, update, and removal do not depend on the calling shell having
initialized Node.js. Removal uninstalls only that npm package and preserves
NVM, Node.js, and unrelated global packages.

`openai-codex-cli` installs OpenAI's official `@openai/codex` npm package for
the default NVM-managed Node.js version and provides the `codex` command.
Removal uninstalls only that package and preserves NVM, Node.js, unrelated
global packages, and user-owned Codex state under `~/.codex`. After
installation, run `codex` and sign in with ChatGPT or configure a user-owned
OpenAI API key; docpunct does not create or store credentials.

Brave Browser, Visual Studio Code, Google Chrome, and GitHub CLI use upstream APT
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

`gpg` installs `gnupg`, `pass`, and `pinentry-curses` without creating or
deleting user keys. Key selection, `pass init`, headless pinentry, and backup
are documented in `features/gpg/HOWTO.md`.

`gcm-gpg` depends on `gpg`. It requires an initialized pass store backed by an
encryption-capable secret key, then downloads and verifies the latest upstream
GCM Debian package and configures GCM with `credentialStore = gpg` in a
separate docpunct-managed Git include. A marked include block is kept at the
end of `~/.gitconfig`, so its empty helper reset and GCM helper override earlier
host helpers such as `store` without deleting those user-owned settings. The
feature fails closed if another global helper remains active after GCM. It
supports GCM's provider-specific authentication and generic HTTPS servers
using a username plus password or personal access token.

The provider may ask for authentication once to populate the new GPG store.

`doublecmd` installs the latest Double Commander GitHub release from the
portable Qt6 Linux tarball for the local architecture. It verifies the
archive's GitHub release API SHA-256 digest before extracting the app to:

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

The upstream Qt6 portable archive is not fully self-contained on Ubuntu.
`debian-gui-packages` installs `libqt6printsupport6`, which provides the Qt6
runtime dependency chain needed by the installed binary.

Removal deletes only those docpunct-owned install paths and leaves Double
Commander user configuration/cache directories alone.

`obsidian` installs the latest official `amd64` Debian package published by
`obsidianmd/obsidian-releases`. The package is verified against the SHA-256
digest in GitHub's release metadata before installation. Other architectures
fail without downloading because upstream currently provides no Debian package
for them. Removal preserves Obsidian configuration, plugins, caches, and vault
data. The digest shares the same GitHub release trust boundary as the package
and is not independent publisher-signature verification.

`rust` installs Rust with the official `rustup` installer.

`node` installs Node.js with `nvm`.

`devcontainer-cli` depends on `node` and provides the `devcontainer` command
from the `@devcontainers/cli` npm package.

`openai-codex-cli` depends on `node` and provides the `codex` command from
OpenAI's official `@openai/codex` npm package.

`python-uv` installs uv with Astral's standalone installer.

`neovim` builds Neovim from source under `~/.cache/docpunct/src/neovim`.

`neovide` installs Neovide with:

```sh
cargo install --locked neovide
```

The Neovide feature sources `$HOME/.cargo/env` before invoking Cargo so it can
work in the same docpunct run that installed Rust.

It also generates a desktop entry from the repository template and writes it to:

```text
~/.local/share/applications/neovide.desktop
```

---

## Dotfiles

Most dotfiles are managed as symbolic links. Shell entrypoint files and
`.gitconfig` are handled additively so docpunct does not replace existing host
configuration.

Example:

```text
~/.config/docpunct/session-env.sh -> /path/to/docpunct/dotfiles/.config/docpunct/session-env.sh
~/.config/docpunct/bash-ext.sh -> /path/to/docpunct/dotfiles/.config/docpunct/bash-ext.sh
```

Docpunct inserts a small marked block near the top of `.profile` that sources
`session-env.sh`, and another near the top of `.bashrc` that sources
`bash-ext.sh`. Existing content remains in place. `bash-ext.sh` sources the
shared environment before adding interactive aliases and NVM completion.
`session-env.sh` also exports `GPG_TTY` when the shell has a real terminal, so
GPG/pass-backed Git Credential Manager prompts can use terminal pinentry.

Install and update replace only docpunct's marked blocks. Removal deletes only
those blocks and the managed fragment links. Foreign shell-entrypoint symlinks
and malformed or duplicated marker blocks are refused rather than rewritten.

Updating an older docpunct installation migrates its whole-file `.profile` and
`.bashrc` symlinks. The original backups are restored when available, then the
additive blocks are inserted.

Git settings are linked as `~/.config/docpunct/gitconfig`. Docpunct adds a
marked include block near the top of the regular `~/.gitconfig`, creating that
file when necessary:

```ini
# >>> docpunct git setup >>>
[include]
    path = ~/.config/docpunct/gitconfig
# <<< docpunct git setup <<<
```

Existing Git settings remain after the block and therefore override conflicting
docpunct defaults. Install, update, and relink keep one canonical block;
removal deletes only that block and the managed fragment link. Updating an
older installation restores its `.gitconfig` backup before migrating the old
whole-file docpunct symlink.

Neovim config is managed as a directory-level symlink:

```text
~/.config/nvim -> /path/to/docpunct/dotfiles/.config/nvim
```

This keeps Neovim, Telescope, language servers, and plugin tooling looking at a
single coherent config tree.

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

The managed dotfiles are:

```text
.config/docpunct/gitconfig
.config/docpunct/session-env.sh
.config/docpunct/bash-ext.sh
.config/nvim
```

Private Git configuration remains outside docpunct scope and is not imported
into the managed dotfiles.

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
install_notice: Complete the user-owned setup described in HOWTO.md.

depends:
  - debian-cli-packages
```

`description`, `install_notice`, and `depends` are optional. An
`install_notice` is printed after a successful first install. If the feature
contains `HOWTO.md`, docpunct also prints its path.

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
relink.sh
```

`relink.sh` is optional and should only repair paths that an installed feature
links directly into the repository. It is run by `docpunct relink`; it must not
perform a package install or update.

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

If a feature script invokes Cargo or Rust tools, source Cargo's environment in
that script before calling them:

```sh
if [ -s "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi
```

Do not rely on `.profile`, `.bashrc`, the Rust feature, or another feature
script to make Cargo available in the current script environment.

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

If `install.sh` fails, docpunct keeps the install error log and attempts the
feature's `remove.sh` as best-effort cleanup. The feature remains unmarked. A
cleanup failure is reported separately and does not replace the original
install failure log.

### Update

A feature must already be installed before it can be updated.

Updating changes only the explicitly requested feature. Docpunct inspects its
full dependency tree and prints commands for dependencies that may also need
attention, in dependency-first order. It suggests `docpunct update` for an
installed dependency and `docpunct install` for a missing dependency, but does
not run either automatically.

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

Run the real Dev Container CLI npm lifecycle test with:

```sh
just test-devcontainer-cli-feature ubuntu=24.04
./bin/docpunct test-devcontainer-cli-feature 24.04
```

This target is intentionally separate from `just test` and
`just test-containers`.

Run the real OpenAI Codex CLI npm lifecycle test with:

```sh
just test-openai-codex-cli-feature ubuntu=24.04
./bin/docpunct test-openai-codex-cli-feature 24.04
```

This target is intentionally separate from `just test` and
`just test-containers`.

Run the isolated Ollama release lifecycle test with:

```sh
just test-ollama-feature ubuntu=24.04
./bin/docpunct test-ollama-feature 24.04
```

The test uses a locally generated, checksummed stand-in release archive. It
exercises selection, installation, update, conservative removal, model-state
preservation, and the post-install model guidance without downloading the
large production runtime.

The Double Commander feature has a separate non-privileged container test
target:

```sh
just test-doublecmd-feature ubuntu=24.04
./bin/docpunct test-doublecmd-feature 24.04
```

The Neovide feature has a separate non-privileged container test target:

```sh
just test-neovide-feature ubuntu=24.04
./bin/docpunct test-neovide-feature 24.04
```

The Obsidian feature has a separate non-privileged container test target:

```sh
just test-obsidian-feature ubuntu=24.04
./bin/docpunct test-obsidian-feature 24.04
```

The GitHub Copilot CLI feature has a separate non-privileged container test:

```sh
just test-github-copilot-cli-feature ubuntu=24.04
./bin/docpunct test-github-copilot-cli-feature 24.04
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
