#!/usr/bin/env bash
set -euo pipefail

package="brave-browser"
keyring="/usr/share/keyrings/brave-browser-archive-keyring.gpg"
source_file="/etc/apt/sources.list.d/brave-browser-release.sources"

if dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii '; then
  sudo apt-get remove -y "$package"
fi
sudo rm -f -- "$source_file" "$keyring"
sudo apt-get update
