#!/usr/bin/env bash
set -euo pipefail

packages=(
  docker-ce
  docker-ce-cli
  containerd.io
  docker-buildx-plugin
  docker-compose-plugin
)

conflicting_packages=(
  docker.io
  docker-compose
  docker-compose-v2
  docker-doc
  podman-docker
  containerd
  runc
)

keyring="/etc/apt/keyrings/docker.asc"
source_file="/etc/apt/sources.list.d/docker.sources"
repo_url="https://download.docker.com/linux/ubuntu"
target_user="${DOCPUNCT_DOCKER_USER:-${SUDO_USER:-${USER:-}}}"
group_user_marker="$DOCPUNCT_STATE_DIR/docker-group-user"

if [[ -z "$target_user" ]]; then
  printf 'Could not determine user to add to the docker group\n' >&2
  exit 1
fi

installed_conflicts=()
for package in "${conflicting_packages[@]}"; do
  if dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii '; then
    installed_conflicts+=("$package")
  fi
done

if [[ "${#installed_conflicts[@]}" -gt 0 ]]; then
  sudo apt-get remove -y "${installed_conflicts[@]}"
fi

. /etc/os-release
suite="${DOCPUNCT_DOCKER_UBUNTU_SUITE:-${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}}"
if [[ -z "$suite" ]]; then
  printf 'Could not determine Ubuntu codename from /etc/os-release\n' >&2
  exit 1
fi

arch="$(dpkg --print-architecture)"

case "$arch" in
  amd64|arm64|armhf|ppc64el|s390x) ;;
  *)
    printf 'Docker APT repository does not support architecture: %s\n' "$arch" >&2
    exit 1
    ;;
esac

if [[ -z "${DOCPUNCT_DOCKER_UBUNTU_SUITE:-}" ]] &&
  ! curl -fsIL "$repo_url/dists/$suite/Release" >/dev/null; then
  case "$suite" in
    resolute)
      printf 'Docker APT suite resolute is not available; falling back to noble\n' >&2
      suite="noble"
      ;;
    *)
      printf 'Docker APT suite is not available: %s\n' "$suite" >&2
      printf 'Set DOCPUNCT_DOCKER_UBUNTU_SUITE to override the Docker repository suite.\n' >&2
      exit 1
      ;;
  esac
fi

sudo install -d -m 0755 /etc/apt/keyrings /etc/apt/sources.list.d
sudo curl -fsSL "$repo_url/gpg" -o "$keyring"
sudo chmod a+r "$keyring"

sudo tee "$source_file" >/dev/null <<EOF
Types: deb
URIs: $repo_url
Suites: $suite
Components: stable
Architectures: $arch
Signed-By: $keyring
EOF

sudo apt-get update
sudo apt-get install -y "${packages[@]}"

if ! id -nG "$target_user" | tr ' ' '\n' | grep -qx docker; then
  mkdir -p "$DOCPUNCT_STATE_DIR"
  printf 'Added %s to the docker group.\n' "$target_user"
  printf '%s\n' "$target_user" >"$group_user_marker"
  sudo usermod -aG docker "$target_user"
  printf 'Run this in your current shell to activate the group now:\n'
  printf '  newgrp docker\n'
fi
