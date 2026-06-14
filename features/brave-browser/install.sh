#!/usr/bin/env bash
set -euo pipefail

package="brave-browser"
keyring="/usr/share/keyrings/brave-browser-archive-keyring.gpg"
source_file="/etc/apt/sources.list.d/brave-browser-release.sources"
arch="$(dpkg --print-architecture)"

case "$arch" in
  amd64|arm64) ;;
  *)
    printf 'Brave Browser APT repository does not support architecture: %s\n' "$arch" >&2
    exit 1
    ;;
esac

sudo install -d -m 0755 /usr/share/keyrings /etc/apt/sources.list.d
sudo curl -fsSLo "$keyring" \
  https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
sudo curl -fsSLo "$source_file" \
  https://brave-browser-apt-release.s3.brave.com/brave-browser.sources

sudo apt-get update
sudo apt-get install -y "$package"
