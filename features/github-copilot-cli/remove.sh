#!/usr/bin/env bash
set -euo pipefail

install_dir="$HOME/.local/share/docpunct/github-copilot-cli"
bin_link="$HOME/.local/bin/copilot"

if [[ -L "$bin_link" ]]; then
  if [[ "$(readlink "$bin_link")" == "$install_dir/copilot" ]]; then
    rm -- "$bin_link"
  else
    printf 'leaving foreign Copilot CLI symlink untouched: %s -> %s\n' \
      "$bin_link" "$(readlink "$bin_link")"
  fi
elif [[ -e "$bin_link" ]]; then
  printf 'leaving foreign Copilot CLI path untouched: %s\n' "$bin_link"
fi

rm -rf -- "$install_dir"
printf 'Keeping GitHub Copilot CLI authentication, configuration, and session data.\n'
