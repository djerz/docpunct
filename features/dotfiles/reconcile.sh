#!/usr/bin/env bash
set -euo pipefail

files_list="$DOCPUNCT_FEATURE_DIR/files.txt"
dotfiles_dir="$DOCPUNCT_ROOT/dotfiles"

trim_dotfile_path() {
  local relpath="$1"
  relpath="${relpath%%#*}"
  relpath="${relpath#"${relpath%%[![:space:]]*}"}"
  relpath="${relpath%"${relpath##*[![:space:]]}"}"
  printf '%s\n' "$relpath"
}

validate_dotfile_path() {
  local relpath="$1"
  [[ -n "$relpath" ]] || return 1
  [[ "$relpath" != /* ]] || { printf 'absolute paths are not allowed in files.txt: %s\n' "$relpath" >&2; exit 1; }
  [[ "$relpath" != *'..'* ]] || { printf 'parent paths are not allowed in files.txt: %s\n' "$relpath" >&2; exit 1; }
}

directory_contains_only_docpunct_links() {
  local target_path="$1" source_path="$2"
  local path current_target

  # Deprecated migration path for the old file-level Neovim symlink layout.
  # Remove after existing machines have run `docpunct update dotfiles`.
  while IFS= read -r path; do
    if [[ -L "$path" ]]; then
      current_target="$(readlink "$path")"
      [[ "$current_target" == "$source_path"/* ]] || return 1
    elif [[ -d "$path" ]]; then
      continue
    else
      return 1
    fi
  done < <(find "$target_path" -mindepth 1 -print)
}

replace_target_with_symlink() {
  local source_path="$1" target_path="$2" backup_path="$3"
  local current_target

  if [[ -L "$target_path" ]]; then
    current_target="$(readlink "$target_path")"
    if [[ "$current_target" == "$source_path" ]]; then
      return 0
    fi
    rm -- "$target_path"
  elif [[ -d "$source_path" && -d "$target_path" ]]; then
    if directory_contains_only_docpunct_links "$target_path" "$source_path"; then
      rm -rf -- "$target_path"
    else
      printf 'refusing to replace %s because it contains non-docpunct files\n' "$target_path" >&2
      exit 1
    fi
  elif [[ -e "$target_path" ]]; then
    if [[ -e "$backup_path" ]]; then
      printf 'refusing to replace %s because backup already exists at %s\n' "$target_path" "$backup_path" >&2
      exit 1
    fi
    mv -- "$target_path" "$backup_path"
  fi

  ln -s -- "$source_path" "$target_path"
}

mkdir -p "$DOCPUNCT_DOTFILES_BACKUP_DIR"

while IFS= read -r relpath || [[ -n "$relpath" ]]; do
  relpath="$(trim_dotfile_path "$relpath")"
  validate_dotfile_path "$relpath" || continue

  source_path="$dotfiles_dir/$relpath"
  target_path="$HOME/$relpath"
  backup_path="$DOCPUNCT_DOTFILES_BACKUP_DIR/$relpath"

  [[ -e "$source_path" ]] || { printf 'missing dotfile source: %s\n' "$source_path" >&2; exit 1; }
  mkdir -p "$(dirname "$target_path")" "$(dirname "$backup_path")"

  replace_target_with_symlink "$source_path" "$target_path" "$backup_path"
done <"$files_list"
