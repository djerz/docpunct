#!/usr/bin/env bash
set -euo pipefail

rm -f -- "$HOME/.local/bin/nvim"
rm -rf -- "$HOME/.local/share/nvim/runtime"
printf 'Left Neovim config, data, cache, and source checkout untouched.\n'

