#!/usr/bin/env bash
set -euo pipefail

install_dir="$HOME/.local/share/fonts/docpunct/nerdfonts"

rm -rf -- "$install_dir"
rmdir --ignore-fail-on-non-empty "$HOME/.local/share/fonts/docpunct" 2>/dev/null || true

if command -v fc-cache >/dev/null 2>&1; then
  fc-cache -f "$HOME/.local/share/fonts"
fi
