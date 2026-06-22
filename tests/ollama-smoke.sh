#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf -- "$tmpdir"' EXIT

home="$tmpdir/home"
cache="$tmpdir/cache"
release_dir="$tmpdir/release"
payload_dir="$release_dir/payload"
fake_bin="$tmpdir/bin"
arch="$(dpkg --print-architecture)"
archive="$release_dir/ollama-linux-${arch}.tar.zst"
mkdir -p "$home" "$cache" "$payload_dir/bin" "$payload_dir/lib/ollama" "$fake_bin"

cat >"$payload_dir/bin/ollama" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'ollama version test\n'
EOF
chmod +x "$payload_dir/bin/ollama"
printf 'runtime\n' >"$payload_dir/lib/ollama/runtime.txt"
tar -C "$payload_dir" -cf - . | zstd -q -o "$archive"
digest="$(sha256sum "$archive" | awk '{print $1}')"
cat >"$release_dir/release.json" <<EOF
{"tag_name":"v-test","assets":[{"name":"ollama-linux-${arch}.tar.zst","browser_download_url":"file://$archive","digest":"sha256:$digest"}]}
EOF

cat >"$fake_bin/systemctl" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
chmod +x "$fake_bin/systemctl"

run_docpunct() {
  env \
    HOME="$home" \
    PATH="$fake_bin:$PATH" \
    DOCPUNCT_CACHE_DIR="$cache" \
    DOCPUNCT_OLLAMA_RELEASE_API_URL="file://$release_dir/release.json" \
    "$repo_root/bin/docpunct" "$@"
}

install_output="$(run_docpunct install ollama)"
[[ "$install_output" == *"Models are not installed automatically."* ]]
[[ "$install_output" == *"features/ollama/HOWTO.md"* ]]
[[ -x "$home/.local/share/docpunct/ollama/bin/ollama" ]]
[[ -L "$home/.local/bin/ollama" ]]
"$home/.local/bin/ollama" --version >/dev/null
grep -qxF '# Managed by docpunct ollama feature' \
  "$home/.config/systemd/user/ollama.service"

mkdir -p "$home/.ollama/models"
printf 'preserve me\n' >"$home/.ollama/models/test-model"
run_docpunct update ollama >/dev/null
run_docpunct remove ollama >/dev/null
[[ ! -e "$home/.local/bin/ollama" ]]
[[ ! -e "$home/.local/share/docpunct/ollama" ]]
[[ ! -e "$home/.config/systemd/user/ollama.service" ]]
[[ "$(cat "$home/.ollama/models/test-model")" == "preserve me" ]]

printf 'ollama smoke tests passed\n'
