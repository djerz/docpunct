#!/usr/bin/env bash
set -euo pipefail

install_dir="$HOME/.local/share/docpunct/doublecmd"
bin_link="$HOME/.local/bin/doublecmd"
applications_dir="$HOME/.local/share/applications"
desktop_file="$applications_dir/doublecmd.desktop"

if [[ -L "$bin_link" ]]; then
  current_target="$(readlink "$bin_link")"
  if [[ "$current_target" == "$install_dir/doublecmd" ]]; then
    rm -- "$bin_link"
  fi
elif [[ -e "$bin_link" ]]; then
  printf 'leaving non-symlink binary untouched: %s\n' "$bin_link"
fi

if [[ -f "$desktop_file" ]]; then
  rm -- "$desktop_file"
fi

if [[ -d "$install_dir" ]]; then
  rm -rf -- "$install_dir"
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$applications_dir" >/dev/null 2>&1 || true
fi
