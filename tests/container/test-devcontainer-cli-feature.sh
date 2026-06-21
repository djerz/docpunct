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
  bash -lc '
    set -euo pipefail
    cd /workspace/docpunct
    ./bin/docpunct install devcontainer-cli
    export NVM_DIR="$HOME/.nvm"
    . "$NVM_DIR/nvm.sh"
    nvm use --silent default
    command -v devcontainer
    devcontainer --version
    npm list --global --depth=0 @devcontainers/cli
    ./bin/docpunct update devcontainer-cli
    ./bin/docpunct remove devcontainer-cli
    hash -r
    ! command -v devcontainer
    ! npm list --global --depth=0 @devcontainers/cli
    command -v node
    command -v npm
  '
