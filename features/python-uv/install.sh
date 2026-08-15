#!/usr/bin/env bash
set -euo pipefail

state_dir="$DOCPUNCT_STATE_DIR/python-uv"
owned_marker="$state_dir/owned-by-docpunct"
uv_path="$HOME/.local/bin/uv"
uvx_path="$HOME/.local/bin/uvx"

mkdir -p "$state_dir"

if [[ -x "$uv_path" ]]; then
  "$uv_path" self update || true
  touch "$owned_marker"
elif command -v uv >/dev/null 2>&1; then
  printf 'Using existing uv outside docpunct ownership: %s\n' "$(command -v uv)"
  uv self update || true
else
  curl -LsSf https://astral.sh/uv/install.sh | sh
  if [[ -x "$uv_path" && -x "$uvx_path" ]]; then
    touch "$owned_marker"
  else
    printf 'uv installer completed but expected binaries were not found under ~/.local/bin\n' >&2
    exit 1
  fi
fi
