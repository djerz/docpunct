#!/usr/bin/env bash
set -euo pipefail

apt-get update
apt-get install -y --no-install-recommends \
  bash \
  ca-certificates \
  shellcheck \
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
    bash -n bin/docpunct features/*/*.sh
    shellcheck bin/docpunct features/*/*.sh
    ./tests/smoke.sh
    ./bin/docpunct install debian-cli-packages
    test -x /usr/bin/fdfind
    test -L "$HOME/.local/bin/fd"
    test "$(readlink "$HOME/.local/bin/fd")" = "/usr/bin/fdfind"
    ./bin/docpunct update debian-cli-packages
  '
