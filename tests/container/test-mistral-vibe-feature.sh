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
    ./bin/docpunct install mistral-vibe
    export PATH="$HOME/.local/bin:$PATH"
    command -v vibe
    command -v vibe-acp
    vibe --version
    uv tool list | grep -Eq "^mistral-vibe "
    mkdir -p "$HOME/.vibe"
    printf "preserve me\n" >"$HOME/.vibe/config.toml"
    ./bin/docpunct update mistral-vibe
    ./bin/docpunct remove mistral-vibe
    hash -r
    ! command -v vibe
    ! command -v vibe-acp
    ! uv tool list | grep -Eq "^mistral-vibe "
    test "$(cat "$HOME/.vibe/config.toml")" = "preserve me"
    command -v uv
  '
