#!/usr/bin/env bash
set -euo pipefail

if [[ -s "$HOME/.cargo/env" ]]; then
  # shellcheck source=/dev/null
  . "$HOME/.cargo/env"
fi

cargo install --locked neovide

applications_dir="$HOME/.local/share/applications"
desktop_file="$applications_dir/neovide.desktop"
mkdir -p "$applications_dir"

sed "s#__HOME__#$HOME#g" "$DOCPUNCT_FEATURE_DIR/neovide.desktop.in" >"$desktop_file"
chmod 0644 "$desktop_file"

if command -v desktop-file-validate >/dev/null 2>&1; then
  desktop-file-validate "$desktop_file"
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$applications_dir" >/dev/null 2>&1 || true
fi
