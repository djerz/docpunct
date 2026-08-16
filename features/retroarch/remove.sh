#!/usr/bin/env bash
set -euo pipefail

packages=(
  retroarch
  libretro-nestopia
  libretro-snes9x
  libretro-gambatte
  libretro-mgba
  libretro-genesisplusgx
  libretro-mupen64plus-next
  libretro-fbneo
)
keyring="/etc/apt/keyrings/libretro-stable.asc"
stable_source_file="/etc/apt/sources.list.d/libretro-stable.sources"
testing_source_file="/etc/apt/sources.list.d/libretro-testing.sources"
testing_preferences_file="/etc/apt/preferences.d/docpunct-libretro-testing"
codename=""
installed_packages=()

for package in "${packages[@]}"; do
  if dpkg-query -W "$package" >/dev/null 2>&1; then
    installed_packages+=("$package")
  fi
done

if [[ "${#installed_packages[@]}" -gt 0 ]]; then
  sudo apt-get remove -y "${installed_packages[@]}"
fi

if [[ -r /etc/os-release ]]; then
  # shellcheck source=/dev/null
  . /etc/os-release
  codename="${VERSION_CODENAME:-}"
fi

sudo rm -f -- "$stable_source_file" "$testing_source_file" "$testing_preferences_file" "$keyring"
if [[ -n "$codename" ]]; then
  sudo rm -f -- \
    "/etc/apt/sources.list.d/libretro-ubuntu-stable-${codename}.list" \
    "/etc/apt/sources.list.d/libretro-ubuntu-stable-${codename}.sources" \
    "/etc/apt/sources.list.d/libretro-ubuntu-testing-${codename}.list" \
    "/etc/apt/sources.list.d/libretro-ubuntu-testing-${codename}.sources"
fi
sudo apt-get update

printf 'Keeping RetroArch user configuration, saves, states, and downloaded content.\n'
