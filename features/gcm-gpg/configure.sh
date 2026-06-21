#!/usr/bin/env bash
set -euo pipefail

gcm_path="$(command -v git-credential-manager)"
config_dir="$HOME/.config/docpunct"
config_file="$config_dir/git-credential-manager.gitconfig"
state_dir="${DOCPUNCT_CACHE_DIR:-$HOME/.cache/docpunct}/state/gcm-gpg"
config_owned_marker="$state_dir/config-written-by-docpunct"
include_path="$HOME/.config/docpunct/git-credential-manager.gitconfig"
# Git expands a leading tilde in include.path; retain the portable dotfile form.
# shellcheck disable=SC2088
portable_include_path='~/.config/docpunct/git-credential-manager.gitconfig'

mkdir -p "$config_dir" "$state_dir"
chmod 0700 "$config_dir"

tmp="$(mktemp "$config_dir/.git-credential-manager.XXXXXX")"
trap 'rm -f -- "$tmp"' EXIT
cat >"$tmp" <<EOF
[credential]
	helper =
	helper = $gcm_path
	credentialStore = gpg
EOF
chmod 0600 "$tmp"
mv -f -- "$tmp" "$config_file"
touch "$config_owned_marker"
trap - EXIT

if ! git config --global --get-all include.path 2>/dev/null |
  grep -Fxq -e "$include_path" -e "$portable_include_path"; then
  git config --global --add include.path "$include_path"
fi

printf 'Configured Git Credential Manager with GPG storage in %s\n' "$config_file"
