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
    ./bin/docpunct install claude-code-cli
    export NVM_DIR="$HOME/.nvm"
    . "$NVM_DIR/nvm.sh"
    nvm use --silent default
    command -v claude
    claude --version
    npm list --global --depth=0 @anthropic-ai/claude-code
    mkdir -p "$HOME/.claude"
    printf "preserve me\n" >"$HOME/.claude/settings.json"
    ./bin/docpunct update claude-code-cli
    ./bin/docpunct remove claude-code-cli
    hash -r
    ! command -v claude
    ! npm list --global --depth=0 @anthropic-ai/claude-code
    test "$(cat "$HOME/.claude/settings.json")" = "preserve me"
    command -v node
    command -v npm
  '
