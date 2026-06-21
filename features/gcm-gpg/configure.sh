#!/usr/bin/env bash
set -euo pipefail

gcm_path="$(command -v git-credential-manager)"
feature_dir="${DOCPUNCT_FEATURE_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
config_dir="$HOME/.config/docpunct"
config_file="$config_dir/git-credential-manager.gitconfig"
state_dir="${DOCPUNCT_CACHE_DIR:-$HOME/.cache/docpunct}/state/gcm-gpg"
config_owned_marker="$state_dir/config-written-by-docpunct"

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

"$feature_dir/git-hooks.sh" install

mapfile -t configured_helpers < <(git config --global --includes --get-all credential.helper)
effective_helpers=()
for helper in "${configured_helpers[@]}"; do
  if [[ -z "$helper" ]]; then
    effective_helpers=()
  else
    effective_helpers+=("$helper")
  fi
done
if [[ "${#effective_helpers[@]}" -ne 1 || "${effective_helpers[0]}" != "$gcm_path" ]]; then
  printf 'refusing insecure Git credential configuration; expected only the gcm-gpg helper after reset\n' >&2
  git config --global --includes --show-origin --get-all credential.helper >&2 || true
  exit 1
fi
if [[ "$(git config --global --includes --get credential.credentialStore)" != gpg ]]; then
  printf 'refusing insecure Git credential configuration; GCM credentialStore is not gpg\n' >&2
  exit 1
fi

printf 'Configured Git Credential Manager with GPG storage in %s\n' "$config_file"
