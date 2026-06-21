#!/usr/bin/env bash
set -euo pipefail

repo="obsidianmd/obsidian-releases"
api_url="https://api.github.com/repos/$repo/releases/latest"
download_dir="$DOCPUNCT_CACHE_DIR/downloads"

arch="$(dpkg --print-architecture)"
if [[ "$arch" != amd64 ]]; then
  printf 'official Obsidian Debian packages do not support architecture: %s\n' "$arch" >&2
  exit 1
fi

mkdir -p "$download_dir"
release_json="$(curl -fsSL "$api_url")"
tag="$(printf '%s\n' "$release_json" | jq -r '.tag_name')"
version="${tag#v}"
asset_name="obsidian_${version}_amd64.deb"
asset_record="$(
  printf '%s\n' "$release_json" |
    jq -r --arg name "$asset_name" '
      .assets[]
      | select(.name == $name)
      | [.browser_download_url, (.digest // "")]
      | @tsv
    ' |
    head -n 1
)"
IFS=$'\t' read -r asset_url asset_digest <<<"$asset_record"

if [[ -z "$asset_url" || "$asset_url" == null ]]; then
  printf 'could not find Obsidian amd64 Debian asset in latest release %s\n' "$tag" >&2
  printf 'available assets:\n' >&2
  printf '%s\n' "$release_json" | jq -r '.assets[].name' >&2
  exit 1
fi

if [[ ! "$asset_digest" =~ ^sha256:([[:xdigit:]]{64})$ ]]; then
  printf 'latest Obsidian release does not provide a valid SHA-256 digest for %s\n' "$asset_name" >&2
  exit 1
fi
expected_sha256="${BASH_REMATCH[1]}"

package_path="$download_dir/$asset_name"
curl -fL "$asset_url" -o "$package_path"
printf '%s  %s\n' "$expected_sha256" "$package_path" |
  sha256sum --check --status || {
    printf 'Obsidian package checksum verification failed: %s\n' "$package_path" >&2
    exit 1
  }

if ! sudo dpkg -i "$package_path"; then
  sudo apt-get install -f -y
fi

dpkg-query -W -f='${Status}\n' obsidian | grep -qx 'install ok installed'
