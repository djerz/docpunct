#!/usr/bin/env bash
set -euo pipefail

package="brave-browser"
keyring="/usr/share/keyrings/brave-browser-archive-keyring.gpg"
source_file="/etc/apt/sources.list.d/brave-browser-release.sources"

sudo apt-get remove -y "$package"
sudo rm -f -- "$source_file" "$keyring"
sudo apt-get update

