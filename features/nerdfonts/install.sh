#!/usr/bin/env bash
set -euo pipefail

repo="ryanoasis/nerd-fonts"
api_url="https://api.github.com/repos/$repo/releases/latest"
download_dir="$DOCPUNCT_CACHE_DIR/downloads/nerdfonts"
install_dir="$HOME/.local/share/fonts/docpunct/nerdfonts"
fonts_parent="$(dirname "$install_dir")"
tmpdir="$(mktemp -d)"
staging_dir="$tmpdir/nerdfonts"

cleanup() {
  rm -rf -- "$tmpdir"
}
trap cleanup EXIT

read_font_assets() {
  grep -Ev '^[[:space:]]*(#|$)' "$DOCPUNCT_FEATURE_DIR/fonts.txt"
}

mkdir -p "$download_dir" "$fonts_parent" "$staging_dir"

release_json="$(curl -fsSL "$api_url")"
tag="$(printf '%s\n' "$release_json" | jq -r '.tag_name')"

mapfile -t font_assets < <(read_font_assets)
for asset_name in "${font_assets[@]}"; do
  asset_url="$(
    printf '%s\n' "$release_json" |
      jq -r --arg name "$asset_name" '
        .assets[]
        | select(.name == $name)
        | .browser_download_url
      ' |
      head -n 1
  )"

  if [[ -z "$asset_url" || "$asset_url" == "null" ]]; then
    printf 'could not find Nerd Fonts asset %s in latest release %s\n' "$asset_name" "$tag" >&2
    printf 'available assets:\n' >&2
    printf '%s\n' "$release_json" | jq -r '.assets[].name' >&2
    exit 1
  fi

  archive_path="$download_dir/$asset_name"
  extract_dir="$tmpdir/${asset_name%.zip}"
  mkdir -p "$extract_dir"

  curl -fL "$asset_url" -o "$archive_path"
  unzip -q -o "$archive_path" -d "$extract_dir"

  found_fonts=0
  while IFS= read -r font_file; do
    cp -- "$font_file" "$staging_dir/"
    found_fonts=1
  done < <(find "$extract_dir" -type f \( -iname '*.ttf' -o -iname '*.otf' \) -print)

  if [[ "$found_fonts" -eq 0 ]]; then
    printf 'no font files found in Nerd Fonts archive: %s\n' "$asset_name" >&2
    exit 1
  fi
done

rm -rf -- "$install_dir"
mv -- "$staging_dir" "$install_dir"

if command -v fc-cache >/dev/null 2>&1; then
  fc-cache -f "$HOME/.local/share/fonts"
else
  printf 'fc-cache not found; installed fonts may require a new session before use.\n' >&2
fi
