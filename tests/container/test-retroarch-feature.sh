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
    ./bin/docpunct install retroarch
    dpkg-query -W -f="\${Status}\n" retroarch | grep -qx "install ok installed"
    dpkg-query -W -f="\${Version}\n" retroarch | grep -q "+ppa"
    test -f /etc/apt/keyrings/libretro-stable.asc
    test -f /etc/apt/sources.list.d/libretro-stable.sources
    apt-cache policy retroarch >"$HOME/retroarch-policy.txt"
    grep -q "ppa.launchpadcontent.net/libretro/stable" "$HOME/retroarch-policy.txt"
    command -v retroarch
    retroarch --version
    ./bin/docpunct update retroarch
    mkdir -p "$HOME/.config/retroarch" "$HOME/.local/share/retroarch/saves"
    touch "$HOME/.config/retroarch/retroarch.cfg" "$HOME/.local/share/retroarch/saves/example.srm"
    ./bin/docpunct remove retroarch
    ! dpkg-query -W -f="\${Status}" retroarch 2>/dev/null | grep -q "install ok installed"
    test ! -e /etc/apt/keyrings/libretro-stable.asc
    test ! -e /etc/apt/sources.list.d/libretro-stable.sources
    test -f "$HOME/.config/retroarch/retroarch.cfg"
    test -f "$HOME/.local/share/retroarch/saves/example.srm"
  '
