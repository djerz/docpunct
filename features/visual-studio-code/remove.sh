#!/usr/bin/env bash
set -euo pipefail

package="code"
keyring="/usr/share/keyrings/microsoft.gpg"
source_file="/etc/apt/sources.list.d/vscode.sources"

sudo apt-get remove -y "$package"
sudo rm -f -- "$source_file" "$keyring"
sudo apt-get update

