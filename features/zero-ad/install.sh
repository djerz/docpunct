#!/usr/bin/env bash
set -euo pipefail

version="${DOCPUNCT_ZERO_AD_VERSION:-0.28.0}"
base_url="${DOCPUNCT_ZERO_AD_BASE_URL:-https://releases.wildfiregames.com}"
asset_name="0ad-${version}-x86_64.AppImage"
download_dir="$DOCPUNCT_CACHE_DIR/downloads"
install_parent="$HOME/.local/share/docpunct"
install_dir="$install_parent/zero-ad"
bin_dir="$HOME/.local/bin"
bin_link="$bin_dir/0ad"
applications_dir="$HOME/.local/share/applications"
desktop_file="$applications_dir/zero-ad.desktop"
appimage_path="$install_dir/$asset_name"

arch="$(dpkg --print-architecture)"
case "$arch" in
  amd64) ;;
  *)
    printf 'official 0 A.D. Release 28 AppImage supports only amd64/x86_64, not: %s\n' "$arch" >&2
    exit 1
    ;;
esac

if [[ -e "$bin_link" || -L "$bin_link" ]]; then
  if [[ ! -L "$bin_link" || "$(readlink "$bin_link")" != "$appimage_path" ]]; then
    printf 'refusing to replace foreign 0 A.D. command: %s\n' "$bin_link" >&2
    exit 1
  fi
fi

missing_packages=()
for package in ca-certificates curl; do
  if ! dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii '; then
    missing_packages+=("$package")
  fi
done
if [[ "${#missing_packages[@]}" -gt 0 ]]; then
  sudo apt-get update
  sudo apt-get install -y "${missing_packages[@]}"
fi

if [[ "${DOCPUNCT_ZERO_AD_SKIP_FUSE_PACKAGE:-0}" != 1 ]]; then
  fuse_package=""
  if dpkg-query -W -f='${db:Status-Abbrev}' libfuse2 2>/dev/null | grep -q '^ii '; then
    fuse_package=""
  elif dpkg-query -W -f='${db:Status-Abbrev}' libfuse2t64 2>/dev/null | grep -q '^ii '; then
    fuse_package=""
  else
    sudo apt-get update
    if apt-cache show libfuse2t64 >/dev/null 2>&1; then
      fuse_package="libfuse2t64"
    elif apt-cache show libfuse2 >/dev/null 2>&1; then
      fuse_package="libfuse2"
    else
      printf 'could not find a libfuse2-compatible package needed by AppImages\n' >&2
      exit 1
    fi
  fi

  if [[ -n "$fuse_package" ]]; then
    sudo apt-get install -y "$fuse_package"
  fi
fi

mkdir -p "$download_dir" "$install_dir" "$bin_dir" "$applications_dir"
curl -fL "$base_url/$asset_name.sha256sum" -o "$download_dir/$asset_name.sha256sum"
curl -fL "$base_url/$asset_name" -o "$download_dir/$asset_name"

(
  cd "$download_dir"
  sha256sum --check --status "$asset_name.sha256sum"
) || {
  printf '0 A.D. AppImage checksum verification failed: %s\n' "$download_dir/$asset_name" >&2
  exit 1
}

install -m 0755 "$download_dir/$asset_name" "$appimage_path"
ln -sfn -- "$appimage_path" "$bin_link"

sed \
  -e "s#__ZERO_AD_EXEC__#$bin_link#g" \
  "$DOCPUNCT_FEATURE_DIR/zero-ad.desktop.in" >"$desktop_file"
chmod 0644 "$desktop_file"

if command -v desktop-file-validate >/dev/null 2>&1; then
  desktop-file-validate "$desktop_file"
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$applications_dir" >/dev/null 2>&1 || true
fi
