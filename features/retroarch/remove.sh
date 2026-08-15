#!/usr/bin/env bash
set -euo pipefail

package="retroarch"
keyring="/etc/apt/keyrings/libretro-stable.asc"
source_file="/etc/apt/sources.list.d/libretro-stable.sources"
codename=""

if dpkg-query -W "$package" >/dev/null 2>&1; then
  sudo apt-get remove -y "$package"
fi

if [[ -r /etc/os-release ]]; then
  # shellcheck source=/dev/null
  . /etc/os-release
  codename="${VERSION_CODENAME:-}"
fi

sudo rm -f -- "$source_file" "$keyring"
if [[ -n "$codename" ]]; then
  sudo rm -f -- \
    "/etc/apt/sources.list.d/libretro-ubuntu-stable-${codename}.list" \
    "/etc/apt/sources.list.d/libretro-ubuntu-stable-${codename}.sources"
fi
sudo apt-get update

printf 'Keeping RetroArch user configuration, saves, states, and downloaded content.\n'
