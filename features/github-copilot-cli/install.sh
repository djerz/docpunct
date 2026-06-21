#!/usr/bin/env bash
set -euo pipefail

repo="github/copilot-cli"
api_url="https://api.github.com/repos/$repo/releases/latest"
download_dir="$DOCPUNCT_CACHE_DIR/downloads"
install_dir="$HOME/.local/share/docpunct/github-copilot-cli"
bin_dir="$HOME/.local/bin"
bin_link="$bin_dir/copilot"
tmpdir="$(mktemp -d)"

cleanup() {
  rm -rf -- "$tmpdir"
}
trap cleanup EXIT

arch="$(dpkg --print-architecture)"
case "$arch" in
  amd64) asset_arch="x64" ;;
  arm64) asset_arch="arm64" ;;
  *)
    printf 'GitHub Copilot CLI does not support Debian architecture: %s\n' "$arch" >&2
    exit 1
    ;;
esac

if [[ -e "$bin_link" || -L "$bin_link" ]]; then
  if [[ ! -L "$bin_link" || "$(readlink "$bin_link")" != "$install_dir/copilot" ]]; then
    printf 'refusing to replace foreign Copilot CLI path: %s\n' "$bin_link" >&2
    exit 1
  fi
fi

mkdir -p "$download_dir" "$(dirname "$install_dir")" "$bin_dir"
release_json="$(curl -fsSL "$api_url")"
tag="$(printf '%s\n' "$release_json" | jq -r '.tag_name')"
asset_name="copilot-linux-${asset_arch}.tar.gz"
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
  printf 'could not find GitHub Copilot CLI Linux %s asset in latest release %s\n' "$asset_arch" "$tag" >&2
  printf 'available assets:\n' >&2
  printf '%s\n' "$release_json" | jq -r '.assets[].name' >&2
  exit 1
fi

if [[ ! "$asset_digest" =~ ^sha256:([[:xdigit:]]{64})$ ]]; then
  printf 'latest GitHub Copilot CLI release does not provide a valid SHA-256 digest for %s\n' "$asset_name" >&2
  exit 1
fi
expected_sha256="${BASH_REMATCH[1]}"

archive_path="$download_dir/$asset_name"
curl -fL "$asset_url" -o "$archive_path"
printf '%s  %s\n' "$expected_sha256" "$archive_path" |
  sha256sum --check --status || {
    printf 'GitHub Copilot CLI checksum verification failed: %s\n' "$archive_path" >&2
    exit 1
  }

tar -xzf "$archive_path" -C "$tmpdir"
[[ -x "$tmpdir/copilot" ]] || {
  printf 'GitHub Copilot CLI executable not found in archive: %s\n' "$asset_name" >&2
  exit 1
}

rm -rf -- "$install_dir"
mkdir -p "$install_dir"
mv -- "$tmpdir/copilot" "$install_dir/copilot"
ln -sfn -- "$install_dir/copilot" "$bin_link"
