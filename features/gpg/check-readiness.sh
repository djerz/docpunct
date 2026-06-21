#!/usr/bin/env bash
set -euo pipefail

password_store_dir="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
gpg_id_file="$password_store_dir/.gpg-id"
howto="$DOCPUNCT_FEATURE_DIR/HOWTO.md"

fail() {
  printf 'GPG credential-store setup is incomplete: %s\n' "$1" >&2
  printf 'Follow %s, then retry.\n' "$howto" >&2
  exit 1
}

command -v gpg >/dev/null 2>&1 || fail 'gpg is not installed'
command -v pass >/dev/null 2>&1 || fail 'pass is not installed'
[[ -s "$gpg_id_file" ]] || fail "pass is not initialized ($gpg_id_file is missing or empty)"

found_recipient=false
while IFS= read -r recipient; do
  [[ -n "$recipient" && "$recipient" != \#* ]] || continue
  found_recipient=true
  if ! gpg --batch --with-colons --list-secret-keys "$recipient" 2>/dev/null |
    awk -F: '$1 == "sec" || $1 == "ssb" { if ($12 ~ /[eE]/) found = 1 } END { exit !found }'; then
    fail "pass recipient '$recipient' has no encryption-capable secret key"
  fi
done <"$gpg_id_file"

[[ "$found_recipient" == true ]] || fail "$gpg_id_file contains no recipients"
