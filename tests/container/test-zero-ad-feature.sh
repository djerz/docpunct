#!/usr/bin/env bash
set -euo pipefail

apt-get update
apt-get install -y --no-install-recommends \
  bash \
  ca-certificates \
  curl \
  sudo
rm -rf /var/lib/apt/lists/*

useradd --create-home --shell /bin/bash docpunct-test
printf 'docpunct-test ALL=(ALL) NOPASSWD:ALL\n' >/etc/sudoers.d/docpunct-test
chmod 0440 /etc/sudoers.d/docpunct-test

sudo -u docpunct-test \
  HOME=/home/docpunct-test \
  DOCPUNCT_CACHE_DIR=/home/docpunct-test/.cache/docpunct \
  DOCPUNCT_ZERO_AD_VERSION=0.28.0 \
  DOCPUNCT_ZERO_AD_BASE_URL=file:///home/docpunct-test/zero-ad-fixture \
  DOCPUNCT_ZERO_AD_SKIP_FUSE_PACKAGE=1 \
  bash -lc '
    set -euo pipefail
    mkdir -p "$HOME/zero-ad-fixture"
    cat >"$HOME/zero-ad-fixture/0ad-0.28.0-x86_64.AppImage" <<'"'"'EOF'"'"'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == --appimage-extract ]]; then
  mkdir -p squashfs-root
  printf "fake png\n" >squashfs-root/.DirIcon
  exit 0
fi
printf "0 A.D. fake AppImage 0.28.0\n"
EOF
    chmod +x "$HOME/zero-ad-fixture/0ad-0.28.0-x86_64.AppImage"
    (
      cd "$HOME/zero-ad-fixture"
      sha256sum 0ad-0.28.0-x86_64.AppImage >0ad-0.28.0-x86_64.AppImage.sha256sum
    )

    cd /workspace/docpunct
    ./bin/docpunct install zero-ad
    test -x "$HOME/.local/share/docpunct/zero-ad/0ad-0.28.0-x86_64.AppImage"
    test -f "$HOME/.local/share/docpunct/zero-ad/zero-ad.png"
    test -x "$HOME/.local/bin/0ad"
    grep -qx "# Managed by docpunct zero-ad feature." "$HOME/.local/bin/0ad"
    grep -Fqx "exec \"$HOME/.local/share/docpunct/zero-ad/0ad-0.28.0-x86_64.AppImage\" \"\$@\"" "$HOME/.local/bin/0ad"
    "$HOME/.local/bin/0ad" | grep -qx "0 A.D. fake AppImage 0.28.0"
    test -f "$HOME/.local/share/applications/zero-ad.desktop"
    grep -qx "Exec=$HOME/.local/bin/0ad" "$HOME/.local/share/applications/zero-ad.desktop"
    grep -qx "Icon=$HOME/.local/share/docpunct/zero-ad/zero-ad.png" "$HOME/.local/share/applications/zero-ad.desktop"
    ./bin/docpunct update zero-ad
    mkdir -p "$HOME/.config/0ad" "$HOME/.local/share/0ad/saves"
    touch "$HOME/.config/0ad/config" "$HOME/.local/share/0ad/saves/example.0adsave"
    ./bin/docpunct remove zero-ad
    test ! -e "$HOME/.local/bin/0ad"
    test ! -e "$HOME/.local/share/docpunct/zero-ad"
    test ! -e "$HOME/.local/share/applications/zero-ad.desktop"
    test -f "$HOME/.config/0ad/config"
    test -f "$HOME/.local/share/0ad/saves/example.0adsave"
  '
