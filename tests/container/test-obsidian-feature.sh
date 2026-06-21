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
    ./bin/docpunct install obsidian
    dpkg-query -W -f="\${Status}\n" obsidian | grep -qx "install ok installed"
    command -v obsidian
    ./bin/docpunct update obsidian
    mkdir -p "$HOME/.config/obsidian" "$HOME/vault"
    touch "$HOME/.config/obsidian/obsidian.json" "$HOME/vault/note.md"
    ./bin/docpunct remove obsidian
    ! dpkg-query -W -f="\${Status}" obsidian 2>/dev/null | grep -q "install ok installed"
    test -f "$HOME/.config/obsidian/obsidian.json"
    test -f "$HOME/vault/note.md"
  '
