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
    ./bin/docpunct install google-earth-pro
    dpkg-query -W -f="\${Status}\n" google-earth-pro-stable | grep -qx "install ok installed"
    command -v google-earth-pro
    test -x /opt/google/earth/pro/googleearth
    test -f /etc/cron.daily/google-earth-pro
    ./bin/docpunct update google-earth-pro
    mkdir -p "$HOME/.googleearth"
    touch "$HOME/.googleearth/myplaces.kml"
    ./bin/docpunct remove google-earth-pro
    ! dpkg-query -W -f="\${Status}" google-earth-pro-stable 2>/dev/null | grep -q "install ok installed"
    test -f "$HOME/.googleearth/myplaces.kml"
  '
