#!/usr/bin/env bash
set -euo pipefail

repo="$DOCPUNCT_SRC_DIR/neovim"
mkdir -p "$DOCPUNCT_SRC_DIR" "$HOME/.local"

if [[ ! -d "$repo/.git" ]]; then
  git clone https://github.com/neovim/neovim.git "$repo"
fi

git -C "$repo" fetch --tags --force
tag="$(git -C "$repo" tag -l 'v[0-9]*' | grep -Ev 'nightly|dev|rc' | sort -V | tail -n 1)"
[[ -n "$tag" ]] || { printf 'could not determine latest stable Neovim tag\n' >&2; exit 1; }
git -C "$repo" checkout "$tag"
make -C "$repo" CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX="$HOME/.local"
make -C "$repo" install

