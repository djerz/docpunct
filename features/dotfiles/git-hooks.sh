#!/usr/bin/env bash
set -euo pipefail

action="${1:-}"
[[ "$action" == install || "$action" == remove ]] || {
  printf 'usage: %s install|remove\n' "$0" >&2
  exit 2
}

target="$HOME/.gitconfig"
backup="$DOCPUNCT_DOTFILES_BACKUP_DIR/.gitconfig"
legacy_source="$DOCPUNCT_ROOT/dotfiles/.gitconfig"
begin_marker='# >>> docpunct git setup >>>'
end_marker='# <<< docpunct git setup <<<'

write_block() {
  printf '%s\n' \
    "$begin_marker" \
    '[include]' \
    '    path = ~/.config/docpunct/gitconfig' \
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
    printf 'refusing to edit %s because its docpunct git markers are malformed or duplicated\n' "$target" >&2
    exit 1
  fi
  if [[ "$begin_count" -eq 1 ]]; then
    begin_line="$(grep -Fn -- "$begin_marker" "$target" | cut -d: -f1)"
    end_line="$(grep -Fn -- "$end_marker" "$target" | cut -d: -f1)"
    if [[ "$begin_line" -ge "$end_line" ]]; then
      printf 'refusing to edit %s because its docpunct git markers are malformed or duplicated\n' "$target" >&2
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

new_temp() {
  local tmp
  tmp="$(mktemp "$(dirname "$target")/.docpunct-git.XXXXXX")"
  if [[ -e "$target" ]]; then
    chmod --reference="$target" "$tmp"
  fi
  printf '%s\n' "$tmp"
}

migrate_legacy_link() {
  local current_target
  [[ -L "$target" ]] || return 0
  current_target="$(readlink "$target")"
  if [[ "$current_target" != "$legacy_source" ]]; then
    printf 'refusing to edit foreign git config symlink: %s -> %s\n' "$target" "$current_target" >&2
    exit 1
  fi

  rm -- "$target"
  if [[ -e "$backup" || -L "$backup" ]]; then
    mv -- "$backup" "$target"
  else
    : >"$target"
  fi
}

install_hook() {
  local body_tmp output_tmp
  mkdir -p "$(dirname "$target")"
  migrate_legacy_link
  if [[ -L "$target" ]]; then
    printf 'refusing to edit foreign git config symlink: %s -> %s\n' "$target" "$(readlink "$target")" >&2
    exit 1
  fi
  [[ -e "$target" ]] || : >"$target"
  validate_markers
  body_tmp="$(mktemp)"
  output_tmp="$(new_temp)"
  without_block >"$body_tmp"
  {
    write_block
    cat "$body_tmp"
  } >"$output_tmp"
  mv -- "$output_tmp" "$target"
  rm -f -- "$body_tmp"
}

remove_hook() {
  local current_target output_tmp
  if [[ -L "$target" ]]; then
    current_target="$(readlink "$target")"
    if [[ "$current_target" == "$legacy_source" ]]; then
      rm -- "$target"
      if [[ -e "$backup" || -L "$backup" ]]; then
        mv -- "$backup" "$target"
      fi
    else
      printf 'leaving foreign git config symlink untouched: %s -> %s\n' "$target" "$current_target"
    fi
    return 0
  fi
  [[ -e "$target" ]] || return 0
  validate_markers
  if [[ "$(marker_count "$begin_marker")" -eq 0 ]]; then
    return 0
  fi
  output_tmp="$(new_temp)"
  without_block >"$output_tmp"
  mv -- "$output_tmp" "$target"
}

if [[ "$action" == install ]]; then
  install_hook
else
  remove_hook
fi
