#!/usr/bin/env bash
set -euo pipefail

package="google-chrome-stable"
keyring="/usr/share/keyrings/google-linux-signing-key.gpg"
source_file="/etc/apt/sources.list.d/google-chrome.sources"
arch="$(dpkg --print-architecture)"

case "$arch" in
  amd64) ;;
  *)
    printf 'Google Chrome APT repository does not support architecture: %s\n' "$arch" >&2
    exit 1
    ;;
esac

sudo install -d -m 0755 /usr/share/keyrings /etc/apt/sources.list.d
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub |
  gpg --dearmor |
  sudo tee "$keyring" >/dev/null

sudo tee "$source_file" >/dev/null <<EOF
Types: deb
URIs: https://dl.google.com/linux/chrome/deb/
Suites: stable
Components: main
Architectures: amd64
Signed-By: $keyring
EOF

sudo apt-get update
sudo apt-get install -y "$package"
