#!/usr/bin/env bash
set -euo pipefail

state_dir="$DOCPUNCT_STATE_DIR/python-uv"
owned_marker="$state_dir/owned-by-docpunct"
uv_path="$HOME/.local/bin/uv"
uvx_path="$HOME/.local/bin/uvx"

if [[ -f "$owned_marker" ]]; then
  rm -f -- "$uv_path" "$uvx_path"
  rm -f -- "$owned_marker"
  rmdir --ignore-fail-on-non-empty "$state_dir" 2>/dev/null || true
else
  printf 'Keeping uv because docpunct ownership is not recorded.\n'
fi

printf 'Keeping uv tool environments, caches, and user configuration.\n'
