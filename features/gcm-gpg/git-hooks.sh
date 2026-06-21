#!/usr/bin/env bash
set -euo pipefail

action="${1:-}"
[[ "$action" == install || "$action" == remove ]] || {
  printf 'usage: %s install|remove\n' "$0" >&2
  exit 2
}

target="$HOME/.gitconfig"
include_path="$HOME/.config/docpunct/git-credential-manager.gitconfig"
# Git expands the leading tilde in include.path; this is the portable value
# written by the managed block.
# shellcheck disable=SC2088
portable_include_path='~/.config/docpunct/git-credential-manager.gitconfig'
begin_marker='# >>> docpunct gcm-gpg >>>'
end_marker='# <<< docpunct gcm-gpg <<<'

write_block() {
  printf '%s\n' \
    "$begin_marker" \
    '[include]' \
    '    path = ~/.config/docpunct/git-credential-manager.gitconfig' \
    "$end_marker"
}

marker_count() {
  local marker="$1"
  grep -Fxc -- "$marker" "$target" 2>/dev/null || true
}

validate_markers() {
  local begin_count end_count begin_line end_line
  begin_count="$(marker_count "$begin_marker")"
  end_count="$(marker_count "$end_marker")"
  if [[ "$begin_count" -gt 1 || "$end_count" -gt 1 || "$begin_count" -ne "$end_count" ]]; then
    printf 'refusing to edit %s because its docpunct gcm-gpg markers are malformed or duplicated\n' "$target" >&2
    exit 1
  fi
  if [[ "$begin_count" -eq 1 ]]; then
    begin_line="$(grep -Fn -- "$begin_marker" "$target" | cut -d: -f1)"
    end_line="$(grep -Fn -- "$end_marker" "$target" | cut -d: -f1)"
    if [[ "$begin_line" -ge "$end_line" ]]; then
      printf 'refusing to edit %s because its docpunct gcm-gpg markers are malformed or duplicated\n' "$target" >&2
      exit 1
    fi
  fi
}

without_block() {
  awk -v begin="$begin_marker" -v end="$end_marker" '
    $0 == begin { in_block=1; next }
    in_block && $0 == end { in_block=0; next }
    !in_block { print }
  ' "$target"
}

remove_include_value() {
  local file="$1" value="$2" status
  if git config --file "$file" --fixed-value --unset-all include.path "$value"; then
    return 0
  fi
  status="$?"
  [[ "$status" -eq 5 ]] || return "$status"
}

new_temp() {
  local tmp
  tmp="$(mktemp "$(dirname "$target")/.docpunct-gcm-gpg.XXXXXX")"
  if [[ -e "$target" ]]; then
    chmod --reference="$target" "$tmp"
  fi
  printf '%s\n' "$tmp"
}

install_hook() {
  local output_tmp
  mkdir -p "$(dirname "$target")"
  if [[ -L "$target" ]]; then
    printf 'refusing to edit git config symlink: %s -> %s\n' "$target" "$(readlink "$target")" >&2
    exit 1
  fi
  [[ -e "$target" ]] || : >"$target"
  validate_markers
  output_tmp="$(new_temp)"
  without_block >"$output_tmp"

  # Deprecated migration path for includes written before gcm-gpg used an
  # ordered marked block. Remove after existing machines have updated gcm-gpg.
  remove_include_value "$output_tmp" "$include_path"
  remove_include_value "$output_tmp" "$portable_include_path"

  printf '\n' >>"$output_tmp"
  write_block >>"$output_tmp"
  mv -- "$output_tmp" "$target"
}

remove_hook() {
  local output_tmp
  [[ -e "$target" || -L "$target" ]] || return 0
  if [[ -L "$target" ]]; then
    printf 'leaving git config symlink untouched: %s -> %s\n' "$target" "$(readlink "$target")"
    return 0
  fi
  validate_markers
  output_tmp="$(new_temp)"
  if [[ "$(marker_count "$begin_marker")" -eq 1 ]]; then
    without_block >"$output_tmp"
  else
    cat "$target" >"$output_tmp"
  fi

  # Also clean up the deprecated unmanaged include if a user removes gcm-gpg
  # before first updating to the marked-block version.
  remove_include_value "$output_tmp" "$include_path"
  remove_include_value "$output_tmp" "$portable_include_path"
  mv -- "$output_tmp" "$target"
}

if [[ "$action" == install ]]; then
  install_hook
else
  remove_hook
fi
