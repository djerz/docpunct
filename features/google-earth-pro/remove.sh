#!/usr/bin/env bash
set -euo pipefail

package="google-earth-pro-stable"
source_file="/etc/apt/sources.list.d/google-earth-pro.sources"
legacy_source_file="/etc/apt/sources.list.d/google-earth-pro.list"

if dpkg-query -W "$package" >/dev/null 2>&1; then
  sudo apt-get remove -y "$package"
fi

sudo rm -f -- "$source_file" "$legacy_source_file"
printf 'Keeping Google Earth Pro user data and saved places.\n'
