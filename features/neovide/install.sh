#!/usr/bin/env bash
set -euo pipefail

if [[ -s "$HOME/.cargo/env" ]]; then
  # shellcheck source=/dev/null
  . "$HOME/.cargo/env"
fi

cargo install --locked neovide

applications_dir="$HOME/.local/share/applications"
desktop_file="$applications_dir/neovide.desktop"
icons_dir="$HOME/.local/share/icons/docpunct"
icon_file="$icons_dir/neovide.ico"
mkdir -p "$applications_dir" "$icons_dir"

cp -- "$DOCPUNCT_FEATURE_DIR/neovide.ico" "$icon_file"
chmod 0644 "$icon_file"

sed \
  -e "s#__HOME__#$HOME#g" \
  -e "s#__NEOVIDE_ICON__#$icon_file#g" \
  "$DOCPUNCT_FEATURE_DIR/neovide.desktop.in" >"$desktop_file"
chmod 0644 "$desktop_file"

if command -v desktop-file-validate >/dev/null 2>&1; then
  desktop-file-validate "$desktop_file"
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$applications_dir" >/dev/null 2>&1 || true
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache "$HOME/.local/share/icons" >/dev/null 2>&1 || true
fi
