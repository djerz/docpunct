#!/usr/bin/env bash
set -euo pipefail

install_dir="$HOME/.local/share/docpunct/zero-ad"
bin_link="$HOME/.local/bin/0ad"
applications_dir="$HOME/.local/share/applications"
desktop_file="$applications_dir/zero-ad.desktop"

if [[ -L "$bin_link" ]]; then
  current_target="$(readlink "$bin_link")"
  case "$current_target" in
    "$install_dir"/*) rm -- "$bin_link" ;;
    *) printf 'leaving foreign 0 A.D. symlink untouched: %s -> %s\n' "$bin_link" "$current_target" ;;
  esac
elif [[ -e "$bin_link" ]]; then
  printf 'leaving foreign 0 A.D. command untouched: %s\n' "$bin_link"
fi

if [[ -f "$desktop_file" ]]; then
  rm -- "$desktop_file"
fi

rm -rf -- "$install_dir"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$applications_dir" >/dev/null 2>&1 || true
fi

printf 'Keeping user 0 A.D. configuration and game data under %s/.config/0ad and %s/.local/share/0ad.\n' "$HOME" "$HOME"
