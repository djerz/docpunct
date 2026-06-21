#!/usr/bin/env bash
set -euo pipefail

package="gh"
keyring="/etc/apt/keyrings/githubcli-archive-keyring.gpg"
source_file="/etc/apt/sources.list.d/github-cli.list"

sudo apt-get remove -y "$package"
sudo rm -f -- "$source_file" "$keyring"
sudo apt-get update
