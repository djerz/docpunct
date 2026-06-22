#!/usr/bin/env bash
set -euo pipefail

install_dir="$HOME/.local/share/docpunct/ollama"
bin_link="$HOME/.local/bin/ollama"
unit_file="$HOME/.config/systemd/user/ollama.service"
unit_marker="# Managed by docpunct ollama feature"

if [[ -f "$unit_file" ]] && grep -qxF "$unit_marker" "$unit_file"; then
  if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user disable --now ollama.service || true
  fi
  rm -- "$unit_file"
  if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user daemon-reload
  fi
elif [[ -e "$unit_file" ]]; then
  printf 'leaving foreign Ollama user service untouched: %s\n' "$unit_file"
fi

if [[ -L "$bin_link" ]]; then
  if [[ "$(readlink "$bin_link")" == "$install_dir/bin/ollama" ]]; then
    rm -- "$bin_link"
  else
    printf 'leaving foreign Ollama symlink untouched: %s -> %s\n' \
      "$bin_link" "$(readlink "$bin_link")"
  fi
elif [[ -e "$bin_link" ]]; then
  printf 'leaving foreign Ollama path untouched: %s\n' "$bin_link"
fi

rm -rf -- "$install_dir"
printf 'Keeping downloaded models and user configuration under %s/.ollama.\n' "$HOME"
