#!/usr/bin/env bash
set -euo pipefail

repo="git-ecosystem/git-credential-manager"
api_url="https://api.github.com/repos/$repo/releases/latest"
download_dir="$DOCPUNCT_CACHE_DIR/downloads"
mkdir -p "$download_dir"

arch="$(dpkg --print-architecture)"
case "$arch" in
  amd64) asset_arch="x64" ;;
  arm64) asset_arch="arm64" ;;
  *)
    printf 'unsupported Debian architecture for Git Credential Manager: %s\n' "$arch" >&2
    exit 1
    ;;
esac

release_json="$(curl -fsSL "$api_url")"
tag="$(printf '%s\n' "$release_json" | jq -r '.tag_name')"
asset_record="$(
  printf '%s\n' "$release_json" |
    jq -r --arg arch "$asset_arch" '
      .assets[]
      | select(.name | test("^gcm-linux-" + $arch + "-.*\\.deb$"))
      | [.browser_download_url, (.digest // "")]
      | @tsv
    ' |
    head -n 1
)"
IFS=$'\t' read -r asset_url asset_digest <<<"$asset_record"

if [[ -z "$asset_url" || "$asset_url" == "null" ]]; then
  printf 'could not find Git Credential Manager Linux %s .deb asset in latest release %s\n' "$asset_arch" "$tag" >&2
  printf 'available assets:\n' >&2
  printf '%s\n' "$release_json" | jq -r '.assets[].name' >&2
  exit 1
fi

if [[ ! "$asset_digest" =~ ^sha256:([[:xdigit:]]{64})$ ]]; then
  printf 'latest Git Credential Manager release does not provide a valid SHA-256 digest for %s\n' "$(basename "$asset_url")" >&2
  exit 1
fi
expected_sha256="${BASH_REMATCH[1]}"

package_path="$download_dir/$(basename "$asset_url")"
curl -fL "$asset_url" -o "$package_path"
printf '%s  %s\n' "$expected_sha256" "$package_path" | sha256sum --check --status - || {
  printf 'Git Credential Manager package checksum verification failed: %s\n' "$package_path" >&2
  exit 1
}

if ! dpkg-query -W -f='${Status}' libicu-dev 2>/dev/null | grep -q 'install ok installed'; then
  sudo apt-get update
  sudo apt-get install -y libicu-dev
fi

if ! sudo dpkg -i "$package_path"; then
  sudo apt-get install -f -y
fi

git-credential-manager configure
git-credential-manager --version
