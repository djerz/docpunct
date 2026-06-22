#!/usr/bin/env bash
set -euo pipefail

repo="ollama/ollama"
api_url="${DOCPUNCT_OLLAMA_RELEASE_API_URL:-https://api.github.com/repos/$repo/releases/latest}"
download_dir="$DOCPUNCT_CACHE_DIR/downloads"
install_dir="$HOME/.local/share/docpunct/ollama"
bin_dir="$HOME/.local/bin"
bin_link="$bin_dir/ollama"
unit_dir="$HOME/.config/systemd/user"
unit_file="$unit_dir/ollama.service"
unit_marker="# Managed by docpunct ollama feature"
tmpdir="$(mktemp -d)"

cleanup() {
  rm -rf -- "$tmpdir"
}
trap cleanup EXIT

arch="$(dpkg --print-architecture)"
case "$arch" in
  amd64|arm64) asset_arch="$arch" ;;
  *)
    printf 'Ollama does not provide a Linux release for Debian architecture: %s\n' "$arch" >&2
    exit 1
    ;;
esac

if [[ -e "$bin_link" || -L "$bin_link" ]]; then
  if [[ ! -L "$bin_link" || "$(readlink "$bin_link")" != "$install_dir/bin/ollama" ]]; then
    printf 'refusing to replace foreign Ollama path: %s\n' "$bin_link" >&2
    exit 1
  fi
fi

if [[ -e "$unit_file" ]] && ! grep -qxF "$unit_marker" "$unit_file"; then
  printf 'refusing to replace foreign Ollama user service: %s\n' "$unit_file" >&2
  exit 1
fi

missing_packages=()
for package in ca-certificates curl jq zstd; do
  if ! dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii '; then
    missing_packages+=("$package")
  fi
done
if [[ "${#missing_packages[@]}" -gt 0 ]]; then
  sudo apt-get update
  sudo apt-get install -y "${missing_packages[@]}"
fi

mkdir -p "$download_dir" "$(dirname "$install_dir")" "$bin_dir" "$unit_dir"
release_json="$(curl -fsSL "$api_url")"
tag="$(printf '%s\n' "$release_json" | jq -r '.tag_name')"
asset_name="ollama-linux-${asset_arch}.tar.zst"
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
  printf 'could not find Ollama Linux %s asset in latest release %s\n' "$asset_arch" "$tag" >&2
  printf 'available assets:\n' >&2
  printf '%s\n' "$release_json" | jq -r '.assets[].name' >&2
  exit 1
fi

if [[ ! "$asset_digest" =~ ^sha256:([[:xdigit:]]{64})$ ]]; then
  printf 'latest Ollama release does not provide a valid SHA-256 digest for %s\n' "$asset_name" >&2
  exit 1
fi
expected_sha256="${BASH_REMATCH[1]}"

archive_path="$download_dir/${tag}-${asset_name}"
curl -fL "$asset_url" -o "$archive_path"
printf '%s  %s\n' "$expected_sha256" "$archive_path" |
  sha256sum --check --status || {
    printf 'Ollama checksum verification failed: %s\n' "$archive_path" >&2
    exit 1
  }

mkdir -p "$tmpdir/extracted"
tar --use-compress-program=unzstd -xf "$archive_path" -C "$tmpdir/extracted"
[[ -x "$tmpdir/extracted/bin/ollama" ]] || {
  printf 'Ollama executable not found in archive: %s\n' "$asset_name" >&2
  exit 1
}

rm -rf -- "$install_dir.new"
mv -- "$tmpdir/extracted" "$install_dir.new"
rm -rf -- "$install_dir"
mv -- "$install_dir.new" "$install_dir"
ln -sfn -- "$install_dir/bin/ollama" "$bin_link"

cat >"$unit_file" <<'EOF'
# Managed by docpunct ollama feature
[Unit]
Description=Ollama local model server
After=network-online.target

[Service]
ExecStart=%h/.local/share/docpunct/ollama/bin/ollama serve
Restart=on-failure
RestartSec=3
Environment=OLLAMA_HOST=127.0.0.1:11434

[Install]
WantedBy=default.target
EOF

if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
  systemctl --user daemon-reload
  systemctl --user enable --now ollama.service
fi
