#!/usr/bin/env bash
set -euo pipefail

package="gh"
keyring="/etc/apt/keyrings/githubcli-archive-keyring.gpg"
source_file="/etc/apt/sources.list.d/github-cli.sources"
legacy_source_file="/etc/apt/sources.list.d/github-cli.list"

if dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii '; then
  sudo apt-get remove -y "$package"
fi
sudo rm -f -- "$source_file" "$legacy_source_file" "$keyring"
sudo apt-get update
