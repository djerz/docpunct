#!/usr/bin/env bash
set -euo pipefail

apt-get update
apt-get install -y --no-install-recommends \
  bash \
  ca-certificates \
  curl \
  jq \
  sudo \
  zstd
rm -rf /var/lib/apt/lists/*

useradd --create-home --shell /bin/bash docpunct-test
printf 'docpunct-test ALL=(ALL) NOPASSWD:ALL\n' >/etc/sudoers.d/docpunct-test
chmod 0440 /etc/sudoers.d/docpunct-test

release_dir="/tmp/ollama-test-release"
payload_dir="$release_dir/payload"
arch="$(dpkg --print-architecture)"
archive="$release_dir/ollama-linux-${arch}.tar.zst"
mkdir -p "$payload_dir/bin" "$payload_dir/lib/ollama"
cat >"$payload_dir/bin/ollama" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--version" || "${1:-}" == "-v" ]]; then
  printf 'ollama version test\n'
fi
EOF
chmod +x "$payload_dir/bin/ollama"
printf 'runtime\n' >"$payload_dir/lib/ollama/runtime.txt"
tar -C "$payload_dir" -cf - . | zstd -q -o "$archive"
digest="$(sha256sum "$archive" | awk '{print $1}')"
cat >"$release_dir/release.json" <<EOF
{
  "tag_name": "v-test",
  "assets": [
    {
      "name": "ollama-linux-${arch}.tar.zst",
      "browser_download_url": "file://$archive",
      "digest": "sha256:$digest"
    }
  ]
}
EOF

sudo -u docpunct-test \
  HOME=/home/docpunct-test \
  DOCPUNCT_CACHE_DIR=/home/docpunct-test/.cache/docpunct \
  DOCPUNCT_OLLAMA_RELEASE_API_URL="file://$release_dir/release.json" \
  bash -lc '
    set -euo pipefail
    cd /workspace/docpunct
    install_output="$(./bin/docpunct install ollama)"
    [[ "$install_output" == *"Models are not installed automatically."* ]]
    [[ "$install_output" == *"features/ollama/HOWTO.md"* ]]
    test -x "$HOME/.local/share/docpunct/ollama/bin/ollama"
    test -L "$HOME/.local/bin/ollama"
    "$HOME/.local/bin/ollama" --version
    grep -qxF "# Managed by docpunct ollama feature" \
      "$HOME/.config/systemd/user/ollama.service"
    grep -qxF "Environment=OLLAMA_HOST=127.0.0.1:11434" \
      "$HOME/.config/systemd/user/ollama.service"
    grep -qxF "Environment=OLLAMA_CONTEXT_LENGTH=65536" \
      "$HOME/.config/systemd/user/ollama.service"
    mkdir -p "$HOME/.ollama/models"
    printf "preserve me\n" >"$HOME/.ollama/models/test-model"
    ./bin/docpunct update ollama
    "$HOME/.local/bin/ollama" --version
    ./bin/docpunct remove ollama
    test ! -e "$HOME/.local/bin/ollama"
    test ! -e "$HOME/.local/share/docpunct/ollama"
    test ! -e "$HOME/.config/systemd/user/ollama.service"
    test "$(cat "$HOME/.ollama/models/test-model")" = "preserve me"
  '
