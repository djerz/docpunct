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
    ./bin/docpunct install openai-codex-cli
    export NVM_DIR="$HOME/.nvm"
    . "$NVM_DIR/nvm.sh"
    nvm use --silent default
    command -v codex
    codex --version
    npm list --global --depth=0 @openai/codex
    mkdir -p "$HOME/.codex"
    printf "preserve me\n" >"$HOME/.codex/config.toml"
    ./bin/docpunct update openai-codex-cli
    ./bin/docpunct remove openai-codex-cli
    hash -r
    ! command -v codex
    ! npm list --global --depth=0 @openai/codex
    test "$(cat "$HOME/.codex/config.toml")" = "preserve me"
    command -v node
    command -v npm
  '
