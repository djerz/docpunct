#!/usr/bin/env bash
set -euo pipefail

profile="/etc/apparmor.d/mbsync"
local_policy="/etc/apparmor.d/local/mbsync"
block="$DOCPUNCT_FEATURE_DIR/mbsync-apparmor.block"
begin_marker='# >>> docpunct epel PassCmd support >>>'
end_marker='# <<< docpunct epel PassCmd support <<<'

# Older supported Ubuntu releases may not ship an mbsync AppArmor profile.
[[ -f "$profile" ]] || exit 0

tmp="$(mktemp)"
cleanup() {
  rm -f -- "$tmp"
}
trap cleanup EXIT

begin_count=0
end_count=0
if [[ -f "$local_policy" ]]; then
  begin_count="$(grep -Fxc "$begin_marker" "$local_policy" || true)"
  end_count="$(grep -Fxc "$end_marker" "$local_policy" || true)"
fi

if [[ "$begin_count" -gt 1 || "$end_count" -gt 1 || "$begin_count" -ne "$end_count" ]]; then
  printf 'refusing to update malformed docpunct block in %s\n' "$local_policy" >&2
  exit 1
fi

if [[ -f "$local_policy" ]]; then
  awk -v begin="$begin_marker" -v end="$end_marker" '
    $0 == begin { managed=1; next }
    $0 == end { managed=0; next }
    !managed { print }
  ' "$local_policy" >"$tmp"
fi

if [[ -s "$tmp" ]]; then
  printf '\n' >>"$tmp"
fi
cat "$block" >>"$tmp"

sudo install -o root -g root -m 0644 "$tmp" "$local_policy"
if command -v apparmor_parser >/dev/null 2>&1; then
  sudo apparmor_parser -r "$profile"
fi
