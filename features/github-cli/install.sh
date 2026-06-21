#!/usr/bin/env bash
set -euo pipefail

package="gh"
keyring="/etc/apt/keyrings/githubcli-archive-keyring.gpg"
source_file="/etc/apt/sources.list.d/github-cli.list"
arch="$(dpkg --print-architecture)"
keyring_sha256="6084d5d7bd8e288441e0e94fc6275570895da18e6751f70f057485dc2d1a811b"
keyring_tmp="$(mktemp)"
trap 'rm -f -- "$keyring_tmp"' EXIT

case "$arch" in
  i386|amd64|armhf|arm64) ;;
  *)
    printf 'GitHub CLI APT repository does not support architecture: %s\n' "$arch" >&2
    exit 1
    ;;
esac

sudo install -d -m 0755 /etc/apt/keyrings /etc/apt/sources.list.d
curl -fsSLo "$keyring_tmp" \
  https://cli.github.com/packages/githubcli-archive-keyring.gpg
printf '%s  %s\n' "$keyring_sha256" "$keyring_tmp" |
  sha256sum --check --status || {
    printf 'GitHub CLI archive keyring checksum verification failed\n' >&2
    exit 1
  }
sudo install -m 0644 "$keyring_tmp" "$keyring"
rm -f -- "$keyring_tmp"
trap - EXIT

printf 'deb [arch=%s signed-by=%s] https://cli.github.com/packages stable main\n' \
  "$arch" "$keyring" |
  sudo tee "$source_file" >/dev/null

sudo apt-get update
sudo apt-get install -y "$package"
