#!/usr/bin/env bash
set -euo pipefail

package="google-earth-pro-stable"
package_url="https://dl.google.com/dl/earth/client/current/google-earth-pro-stable_current_amd64.deb"
download_dir="$DOCPUNCT_CACHE_DIR/downloads"
package_path="$download_dir/google-earth-pro-stable_current_amd64.deb"
arch="$(dpkg --print-architecture)"

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
