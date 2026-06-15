#!/usr/bin/env bash
set -euo pipefail

apt-get update
apt-get install -y --no-install-recommends \
  bash \
  ca-certificates \
  sudo
rm -rf /var/lib/apt/lists/*

useradd --create-home --shell /bin/bash docpunct-test
printf 'docpunct-test ALL=(ALL) NOPASSWD:ALL\n' >/etc/sudoers.d/docpunct-test
chmod 0440 /etc/sudoers.d/docpunct-test

sudo -u docpunct-test \
  HOME=/home/docpunct-test \
  DOCPUNCT_CACHE_DIR=/home/docpunct-test/.cache/docpunct \
  bash -lc '
    set -euo pipefail
    cd /workspace/docpunct
    ./bin/docpunct install neovide
    test -x "$HOME/.cargo/bin/neovide"
    test -f "$HOME/.local/share/applications/neovide.desktop"
    "$HOME/.cargo/bin/neovide" --version
    ./bin/docpunct remove neovide
    test ! -e "$HOME/.cargo/bin/neovide"
    test ! -e "$HOME/.local/share/applications/neovide.desktop"
  '
