#!/usr/bin/env bash
set -euo pipefail

action="${1:-}"
[[ "$action" == install || "$action" == remove ]] || {
  printf 'usage: %s install|remove\n' "$0" >&2
  exit 2
}

dotfiles_dir="$DOCPUNCT_ROOT/dotfiles"
begin_marker='# >>> docpunct shell setup >>>'
end_marker='# <<< docpunct shell setup <<<'

legacy_source_for() {
  case "$1" in
    .profile) printf '%s/.profile\n' "$dotfiles_dir" ;;
    .bashrc) printf '%s/.bashrc\n' "$dotfiles_dir" ;;
  esac
}

write_block() {
  local relpath="$1"
  printf '%s\n' "$begin_marker"
  case "$relpath" in
    .profile)
      printf '%s\n' \
        "if [ -r \"\$HOME/.config/docpunct/session-env.sh\" ]; then" \
        "    . \"\$HOME/.config/docpunct/session-env.sh\"" \
        'fi'
      ;;
    .bashrc)
      printf '%s\n' \
        "if [ -r \"\$HOME/.config/docpunct/bash-ext.sh\" ]; then" \
        "    . \"\$HOME/.config/docpunct/bash-ext.sh\"" \
        'fi'
      ;;
  esac
  printf '%s\n' "$end_marker"
}

marker_count() {
  local marker="$1" target="$2"
  grep -Fxc -- "$marker" "$target" 2>/dev/null || true
}

validate_markers() {
  local target="$1" begin_count end_count begin_line end_line
  begin_count="$(marker_count "$begin_marker" "$target")"
  end_count="$(marker_count "$end_marker" "$target")"
  if [[ "$begin_count" -gt 1 || "$end_count" -gt 1 || "$begin_count" -ne "$end_count" ]]; then
    printf 'refusing to edit %s because its docpunct shell markers are malformed or duplicated\n' "$target" >&2
    exit 1
  fi
  if [[ "$begin_count" -eq 1 ]]; then
    begin_line="$(grep -Fn -- "$begin_marker" "$target" | cut -d: -f1)"
    end_line="$(grep -Fn -- "$end_marker" "$target" | cut -d: -f1)"
    if [[ "$begin_line" -ge "$end_line" ]]; then
      printf 'refusing to edit %s because its docpunct shell markers are malformed or duplicated\n' "$target" >&2
      exit 1
    fi
  fi
}

without_block() {
  local target="$1"
  awk -v begin="$begin_marker" -v end="$end_marker" '
    $0 == begin { in_block=1; next }
    in_block && $0 == end { in_block=0; next }
    !in_block { print }
  ' "$target"
}

new_temp_for() {
  local target="$1" tmp
  tmp="$(mktemp "$(dirname "$target")/.docpunct-shell.XXXXXX")"
  if [[ -e "$target" ]]; then
    chmod --reference="$target" "$tmp"
  fi
  printf '%s\n' "$tmp"
}

migrate_legacy_link() {
  local relpath="$1" target="$2" backup="$3" legacy_source current_target
  [[ -L "$target" ]] || return 0
  current_target="$(readlink "$target")"
  legacy_source="$(legacy_source_for "$relpath")"
  if [[ "$current_target" != "$legacy_source" ]]; then
    printf 'refusing to edit foreign shell symlink: %s -> %s\n' "$target" "$current_target" >&2
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
  local relpath="$1" target="$HOME/$1" backup="$DOCPUNCT_DOTFILES_BACKUP_DIR/$1"
  local body_tmp output_tmp
  mkdir -p "$(dirname "$target")"
  migrate_legacy_link "$relpath" "$target" "$backup"

  if [[ -L "$target" ]]; then
    printf 'refusing to edit foreign shell symlink: %s -> %s\n' "$target" "$(readlink "$target")" >&2
    exit 1
  fi
  [[ -e "$target" ]] || : >"$target"
  validate_markers "$target"
  body_tmp="$(mktemp)"
  output_tmp="$(new_temp_for "$target")"
  without_block "$target" >"$body_tmp"
  {
    write_block "$relpath"
    cat "$body_tmp"
  } >"$output_tmp"
  mv -- "$output_tmp" "$target"
  rm -f -- "$body_tmp"
}

remove_hook() {
  local relpath="$1" target="$HOME/$1" backup="$DOCPUNCT_DOTFILES_BACKUP_DIR/$1"
  local legacy_source current_target output_tmp
  if [[ -L "$target" ]]; then
    current_target="$(readlink "$target")"
    legacy_source="$(legacy_source_for "$relpath")"
    if [[ "$current_target" == "$legacy_source" ]]; then
      rm -- "$target"
      if [[ -e "$backup" || -L "$backup" ]]; then
        mv -- "$backup" "$target"
      fi
    else
      printf 'leaving foreign shell symlink untouched: %s -> %s\n' "$target" "$current_target"
    fi
    return 0
  fi
  [[ -e "$target" ]] || return 0
  validate_markers "$target"
  if [[ "$(marker_count "$begin_marker" "$target")" -eq 0 ]]; then
    return 0
  fi
  output_tmp="$(new_temp_for "$target")"
  without_block "$target" >"$output_tmp"
  mv -- "$output_tmp" "$target"
}

for relpath in .profile .bashrc; do
  if [[ "$action" == install ]]; then
    install_hook "$relpath"
  else
    remove_hook "$relpath"
  fi
done
