#!/usr/bin/env bash
set -euo pipefail

package="google-earth-pro-stable"
package_url="https://dl.google.com/dl/earth/client/current/google-earth-pro-stable_current_amd64.deb"
download_dir="$DOCPUNCT_CACHE_DIR/downloads"
package_path="$download_dir/google-earth-pro-stable_current_amd64.deb"
source_file="/etc/apt/sources.list.d/google-earth-pro.sources"
legacy_source_file="/etc/apt/sources.list.d/google-earth-pro.list"
keyring="/etc/apt/trusted.gpg.d/google-earth-pro.gpg"
arch="$(dpkg --print-architecture)"

modernize_google_earth_source() {
  local attempts_left=10

  while (( attempts_left > 0 )); do
    [[ -e "$keyring" ]] && break
    sleep 1
    attempts_left=$((attempts_left - 1))
  done
  if [[ ! -e "$keyring" ]]; then
    printf 'Google Earth Pro package did not create expected keyring: %s\n' "$keyring" >&2
    exit 1
  fi

  printf 'Types: deb\nURIs: http://dl.google.com/linux/earth/deb/\nSuites: stable\nComponents: main\nArchitectures: amd64\nSigned-By: %s\n' \
    "$keyring" |
    sudo tee "$source_file" >/dev/null
  sudo rm -f -- "$legacy_source_file"
}

case "$arch" in
  amd64) ;;
  *)
    printf 'Google Earth Pro Debian package does not support architecture: %s\n' "$arch" >&2
    exit 1
    ;;
esac

mkdir -p "$download_dir"
curl -fL "$package_url" -o "$package_path"

sudo apt-get update
sudo apt-get install -y xdg-utils
sudo apt-get install -y "$package_path"

dpkg-query -W -f='${Status}\n' "$package" | grep -qx 'install ok installed'
modernize_google_earth_source
