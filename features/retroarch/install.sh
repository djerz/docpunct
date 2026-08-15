#!/usr/bin/env bash
set -euo pipefail

package="retroarch"
keyring="/etc/apt/keyrings/libretro-stable.asc"
source_file="/etc/apt/sources.list.d/libretro-stable.sources"
arch="$(dpkg --print-architecture)"
codename=""
keyring_sha256="bda2a6fc6ea2a716e40ba7e4d7fab2a5775b224918212b9118e629771f683755"
keyring_tmp="$(mktemp)"
trap 'rm -f -- "$keyring_tmp"' EXIT

case "$arch" in
  amd64|arm64|armhf) ;;
  *)
    printf 'Libretro Stable PPA does not support architecture: %s\n' "$arch" >&2
    exit 1
    ;;
esac

if [[ -r /etc/os-release ]]; then
  # shellcheck source=/dev/null
  . /etc/os-release
  codename="${VERSION_CODENAME:-}"
fi

if [[ -z "$codename" ]]; then
  printf 'Unable to determine Ubuntu codename for Libretro Stable PPA\n' >&2
  exit 1
fi

sudo install -d -m 0755 /etc/apt/keyrings /etc/apt/sources.list.d
curl -fsSLo "$keyring_tmp" \
  'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3B2BA0B6750986899B189AFF18DAAE7FECA3745F'
printf '%s  %s\n' "$keyring_sha256" "$keyring_tmp" |
  sha256sum --check --status || {
    printf 'Libretro Stable PPA signing key checksum verification failed\n' >&2
    exit 1
  }
sudo install -m 0644 "$keyring_tmp" "$keyring"
rm -f -- "$keyring_tmp"
trap - EXIT

sudo rm -f -- \
  "/etc/apt/sources.list.d/libretro-ubuntu-stable-${codename}.list" \
  "/etc/apt/sources.list.d/libretro-ubuntu-stable-${codename}.sources"
printf 'Types: deb\nURIs: https://ppa.launchpadcontent.net/libretro/stable/ubuntu\nSuites: %s\nComponents: main\nArchitectures: %s\nSigned-By: %s\n' \
  "$codename" "$arch" "$keyring" |
  sudo tee "$source_file" >/dev/null

sudo apt-get update
sudo apt-get install -y "$package"
