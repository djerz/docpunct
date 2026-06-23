#!/usr/bin/env bash
set -euo pipefail

config_file="$HOME/.config/docpunct/git-credential-manager.gitconfig"
feature_dir="${DOCPUNCT_FEATURE_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
state_dir="$DOCPUNCT_CACHE_DIR/state/gcm-gpg"
package_owned_marker="$state_dir/package-installed-by-docpunct"
config_owned_marker="$state_dir/config-written-by-docpunct"
stale_legacy_marker="$DOCPUNCT_CACHE_DIR/state/installed/git-credential-manager"

if [[ -f "$config_owned_marker" ]]; then
  "$feature_dir/git-hooks.sh" remove
  rm -f -- "$config_file" "$config_owned_marker"
fi

if [[ -f "$package_owned_marker" ]]; then
  if dpkg-query -W -f='${Status}' gcm 2>/dev/null | grep -q 'install ok installed'; then
    sudo dpkg -r gcm
  fi
  rm -f -- "$package_owned_marker"
else
  printf 'Keeping the pre-existing shared gcm package.\n'
fi
rm -f -- "$stale_legacy_marker"

printf 'Keeping GPG keys and pass data. Preserved host credential helpers are active again.\n'
