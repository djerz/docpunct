#!/usr/bin/env bash
set -euo pipefail

bin_dir="$HOME/.local/bin"
fd_link="$bin_dir/fd"

sudo apt-get update
sudo apt-get install -y fd-find

fdfind_path="$(command -v fdfind)"
mkdir -p "$bin_dir"

if [[ -L "$fd_link" ]]; then
  rm -- "$fd_link"
elif [[ -e "$fd_link" ]]; then
  printf 'refusing to replace non-symlink fd command: %s\n' "$fd_link" >&2
  exit 1
fi

ln -s -- "$fdfind_path" "$fd_link"
