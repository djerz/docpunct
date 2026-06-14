#!/usr/bin/env bash
set -euo pipefail

package="google-chrome-stable"
keyring="/usr/share/keyrings/google-linux-signing-key.gpg"
source_file="/etc/apt/sources.list.d/google-chrome.sources"

sudo apt-get remove -y "$package"
sudo rm -f -- "$source_file" "$keyring"
sudo apt-get update

