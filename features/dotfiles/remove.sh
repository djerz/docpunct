#!/usr/bin/env bash
set -euo pipefail

files_list="$DOCPUNCT_FEATURE_DIR/files.txt"
dotfiles_dir="$DOCPUNCT_ROOT/dotfiles"

"$DOCPUNCT_FEATURE_DIR/shell-hooks.sh" remove

while IFS= read -r relpath || [[ -n "$relpath" ]]; do
  relpath="${relpath%%#*}"
  relpath="${relpath#"${relpath%%[![:space:]]*}"}"
  relpath="${relpath%"${relpath##*[![:space:]]}"}"
  [[ -n "$relpath" ]] || continue

  source_path="$dotfiles_dir/$relpath"
  target_path="$HOME/$relpath"
  backup_path="$DOCPUNCT_DOTFILES_BACKUP_DIR/$relpath"

  if [[ -L "$target_path" ]]; then
    current_target="$(readlink "$target_path")"
    if [[ "$current_target" == "$source_path" || "$current_target" == "$dotfiles_dir/"* ]]; then
      rm -- "$target_path"
    fi
  elif [[ -e "$target_path" ]]; then
    printf 'leaving non-symlink dotfile target untouched: %s\n' "$target_path"
    continue
  fi

  if [[ -e "$backup_path" && ! -e "$target_path" ]]; then
    mkdir -p "$(dirname "$target_path")"
    mv -- "$backup_path" "$target_path"
  fi
done <"$files_list"
