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
    ./bin/docpunct install github-copilot-cli
    test -x "$HOME/.local/share/docpunct/github-copilot-cli/copilot"
    test -L "$HOME/.local/bin/copilot"
    "$HOME/.local/bin/copilot" --version
    ./bin/docpunct update github-copilot-cli
    mkdir -p "$HOME/.copilot"
    touch "$HOME/.copilot/config.json"
    ./bin/docpunct remove github-copilot-cli
    test ! -e "$HOME/.local/bin/copilot"
    test ! -e "$HOME/.local/share/docpunct/github-copilot-cli"
    test -f "$HOME/.copilot/config.json"
  '
