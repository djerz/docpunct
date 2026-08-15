#!/usr/bin/env bash
set -euo pipefail

package="code"
keyring="/usr/share/keyrings/microsoft.gpg"
source_file="/etc/apt/sources.list.d/vscode.sources"

if dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii '; then
  sudo apt-get remove -y "$package"
fi
sudo rm -f -- "$source_file" "$keyring"
sudo apt-get update
