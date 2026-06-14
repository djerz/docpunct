#!/usr/bin/env bash
set -euo pipefail

fd_link="$HOME/.local/bin/fd"

if [[ -L "$fd_link" ]]; then
  current_target="$(readlink "$fd_link")"
  if [[ "$(basename "$current_target")" == fdfind ]]; then
    rm -- "$fd_link"
  fi
elif [[ -e "$fd_link" ]]; then
  printf 'leaving non-symlink fd command untouched: %s\n' "$fd_link"
fi

if dpkg-query -W -f='${db:Status-Abbrev}' fd-find 2>/dev/null | grep -q '^ii '; then
  sudo apt-get remove -y fd-find
fi
