#!/usr/bin/env bash
set -euo pipefail

repo="doublecmd/doublecmd"
api_url="https://api.github.com/repos/$repo/releases/latest"
download_dir="$DOCPUNCT_CACHE_DIR/downloads"
install_parent="$HOME/.local/share/docpunct"
install_dir="$install_parent/doublecmd"
bin_dir="$HOME/.local/bin"
bin_link="$bin_dir/doublecmd"
applications_dir="$HOME/.local/share/applications"
desktop_file="$applications_dir/doublecmd.desktop"
tmpdir="$(mktemp -d)"

cleanup() {
  rm -rf -- "$tmpdir"
}
trap cleanup EXIT

mkdir -p "$download_dir" "$install_parent" "$bin_dir" "$applications_dir"

arch="$(dpkg --print-architecture)"
case "$arch" in
  amd64) asset_arch="x86_64" ;;
  arm64) asset_arch="aarch64" ;;
  *)
    printf 'unsupported Debian architecture for Double Commander: %s\n' "$arch" >&2
    exit 1
    ;;
esac

release_json="$(curl -fsSL "$api_url")"
tag="$(printf '%s\n' "$release_json" | jq -r '.tag_name')"
version="${tag#v}"
asset_name="doublecmd-${version}.qt6.${asset_arch}.tar.xz"
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
  printf 'could not find Double Commander Qt6 %s asset in latest release %s\n' "$asset_arch" "$tag" >&2
  printf 'available assets:\n' >&2
  printf '%s\n' "$release_json" | jq -r '.assets[].name' >&2
  exit 1
fi

archive_path="$download_dir/$asset_name"
curl -fL "$asset_url" -o "$archive_path"

tar -xJf "$archive_path" -C "$tmpdir"
[[ -x "$tmpdir/doublecmd/doublecmd" ]] || {
  printf 'Double Commander executable not found in archive: %s\n' "$asset_name" >&2
  exit 1
}

rm -rf -- "$install_dir"
mv -- "$tmpdir/doublecmd" "$install_dir"
ln -sfn -- "$install_dir/doublecmd" "$bin_link"

sed \
  -e "s#__DOUBLECMD_EXEC__#$install_dir/doublecmd#g" \
  -e "s#__DOUBLECMD_ICON__#$install_dir/doublecmd.png#g" \
  "$DOCPUNCT_FEATURE_DIR/doublecmd.desktop.in" >"$desktop_file"
chmod 0644 "$desktop_file"

if command -v desktop-file-validate >/dev/null 2>&1; then
  desktop-file-validate "$desktop_file"
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$applications_dir" >/dev/null 2>&1 || true
fi
