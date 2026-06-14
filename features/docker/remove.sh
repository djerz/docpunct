#!/usr/bin/env bash
set -euo pipefail

packages=(
  docker-ce
  docker-ce-cli
  containerd.io
  docker-buildx-plugin
  docker-compose-plugin
)

keyring="/etc/apt/keyrings/docker.asc"
source_file="/etc/apt/sources.list.d/docker.sources"
target_user="${DOCPUNCT_DOCKER_USER:-}"
group_user_marker="$DOCPUNCT_STATE_DIR/docker-group-user"

if [[ -z "$target_user" ]]; then
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER:-}" != root ]]; then
    target_user="$SUDO_USER"
  else
    target_user="${USER:-}"
  fi
fi

if [[ -z "$target_user" ]]; then
  printf 'Could not determine user to remove from the docker group\n' >&2
  exit 1
fi

if [[ -f "$group_user_marker" ]]; then
  target_user="$(<"$group_user_marker")"
  if getent group docker >/dev/null && id -nG "$target_user" | tr ' ' '\n' | grep -qx docker; then
    sudo gpasswd -d "$target_user" docker
  fi
  rm -f -- "$group_user_marker"
fi

sudo apt-get remove -y "${packages[@]}"
sudo rm -f -- "$source_file" "$keyring"
sudo apt-get update

if getent group docker >/dev/null; then
  printf 'The docker group was left in place.\n'
  printf 'Remove it manually if it is no longer needed:\n'
  printf '  sudo groupdel docker\n'
fi
