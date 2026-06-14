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
    ./bin/docpunct install docker
    test "$(cat "$DOCPUNCT_CACHE_DIR/state/docker-group-user")" = "docpunct-test"
    getent group docker | grep -Eq "[:,]docpunct-test(,|$)"
    id -nG docpunct-test | tr " " "\n" | grep -qx docker
    docker --version
    docker compose version
    ./bin/docpunct remove docker
    getent group docker >/dev/null
    ! getent group docker | grep -Eq "[:,]docpunct-test(,|$)"
    ! id -nG docpunct-test | tr " " "\n" | grep -qx docker
    test ! -e "$DOCPUNCT_CACHE_DIR/state/docker-group-user"
  '
