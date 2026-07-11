#!/usr/bin/env bash
set -euo pipefail

package="google-earth-pro-stable"

if dpkg-query -W "$package" >/dev/null 2>&1; then
  sudo apt-get remove -y "$package"
fi

printf 'Keeping Google Earth Pro user data and saved places.\n'
