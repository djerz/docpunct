#!/usr/bin/env bash
set -euo pipefail

files_list="$DOCPUNCT_FEATURE_DIR/files.txt"
dotfiles_dir="$DOCPUNCT_ROOT/dotfiles"

mkdir -p "$DOCPUNCT_DOTFILES_BACKUP_DIR"

while IFS= read -r relpath || [[ -n "$relpath" ]]; do
  relpath="${relpath%%#*}"
  relpath="${relpath#"${relpath%%[![:space:]]*}"}"
  relpath="${relpath%"${relpath##*[![:space:]]}"}"
  [[ -n "$relpath" ]] || continue
  [[ "$relpath" != /* ]] || { printf 'absolute paths are not allowed in files.txt: %s\n' "$relpath" >&2; exit 1; }
  [[ "$relpath" != *'..'* ]] || { printf 'parent paths are not allowed in files.txt: %s\n' "$relpath" >&2; exit 1; }

  source_path="$dotfiles_dir/$relpath"
  target_path="$HOME/$relpath"
  backup_path="$DOCPUNCT_DOTFILES_BACKUP_DIR/$relpath"

  [[ -e "$source_path" ]] || { printf 'missing dotfile source: %s\n' "$source_path" >&2; exit 1; }
  mkdir -p "$(dirname "$target_path")" "$(dirname "$backup_path")"

  if [[ -L "$target_path" ]]; then
    current_target="$(readlink "$target_path")"
    if [[ "$current_target" == "$source_path" ]]; then
      continue
    fi
    rm -- "$target_path"
  elif [[ -e "$target_path" ]]; then
    if [[ -e "$backup_path" ]]; then
      printf 'refusing to replace %s because backup already exists at %s\n' "$target_path" "$backup_path" >&2
      exit 1
    fi
    mv -- "$target_path" "$backup_path"
  fi

  ln -s -- "$source_path" "$target_path"
done <"$files_list"

