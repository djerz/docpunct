#!/usr/bin/env bash
set -euo pipefail

state_dir="$DOCPUNCT_STATE_DIR/python-uv"
owned_marker="$state_dir/owned-by-docpunct"
uv_path="$HOME/.local/bin/uv"

mkdir -p "$state_dir"

if [[ ! -f "$owned_marker" && -x "$uv_path" && -f "$DOCPUNCT_INSTALLED_DIR/python-uv" ]]; then
  touch "$owned_marker"
  printf 'Adopted existing docpunct python-uv install for managed removal.\n'
fi

if [[ -x "$uv_path" ]]; then
  "$uv_path" self update
elif command -v uv >/dev/null 2>&1; then
  printf 'Updating existing uv outside docpunct ownership: %s\n' "$(command -v uv)"
  uv self update
else
  printf 'uv is not available; reinstalling with the official standalone installer.\n'
  "$DOCPUNCT_FEATURE_DIR/install.sh"
fi
