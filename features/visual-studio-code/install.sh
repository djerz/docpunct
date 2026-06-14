#!/usr/bin/env bash
set -euo pipefail

package="code"
keyring="/usr/share/keyrings/microsoft.gpg"
source_file="/etc/apt/sources.list.d/vscode.sources"

sudo install -d -m 0755 /usr/share/keyrings /etc/apt/sources.list.d
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc |
  gpg --dearmor |
  sudo tee "$keyring" >/dev/null

sudo tee "$source_file" >/dev/null <<EOF
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64 arm64 armhf
Signed-By: $keyring
EOF

sudo apt-get update
sudo apt-get install -y "$package"

