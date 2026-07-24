#!/usr/bin/env bash
set -euo pipefail

config_file="$HOME/.config/docpunct/git-credential-manager.gitconfig"
feature_dir="${DOCPUNCT_FEATURE_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
gcm_gpg_feature_dir="$(dirname "$feature_dir")/gcm-gpg"
state_dir="$DOCPUNCT_CACHE_DIR/state/gcm-keyring"
package_owned_marker="$state_dir/package-installed-by-docpunct"
config_owned_marker="$state_dir/config-written-by-docpunct"
other_package_owned_marker="$DOCPUNCT_CACHE_DIR/state/gcm-gpg/package-installed-by-docpunct"
stale_legacy_marker="$DOCPUNCT_CACHE_DIR/state/installed/git-credential-manager"

active_store=""
if [[ -f "$config_file" ]]; then
  active_store="$(git config --file "$config_file" --get credential.credentialStore || true)"
fi

if [[ -f "$config_owned_marker" && "$active_store" == secretservice ]]; then
  "$gcm_gpg_feature_dir/git-hooks.sh" remove
  rm -f -- "$config_file" "$config_owned_marker"
elif [[ -f "$config_owned_marker" ]]; then
  rm -f -- "$config_owned_marker"
  printf 'Keeping active Git Credential Manager configuration for %s.\n' "${active_store:-another backend}"
fi

if [[ -f "$package_owned_marker" ]]; then
  if [[ -f "$other_package_owned_marker" ]]; then
    printf 'Keeping the shared gcm package because gcm-gpg also uses it.\n'
  elif dpkg-query -W -f='${Status}' gcm 2>/dev/null | grep -q 'install ok installed'; then
    sudo dpkg -r gcm
  fi
  rm -f -- "$package_owned_marker"
else
  printf 'Keeping the pre-existing shared gcm package.\n'
fi
rm -f -- "$stale_legacy_marker"

printf 'Keeping desktop keyring data. Preserved host credential helpers are active again when no GCM backend remains.\n'
