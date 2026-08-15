#!/usr/bin/env bash
set -euo pipefail

package="google-chrome-stable"
keyring="/usr/share/keyrings/google-linux-signing-key.gpg"
source_file="/etc/apt/sources.list.d/google-chrome.sources"

if dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii '; then
  sudo apt-get remove -y "$package"
fi
sudo rm -f -- "$source_file" "$keyring"
sudo apt-get update
