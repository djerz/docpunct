#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=features/debian-gui-packages/package-helpers.sh
. "$DOCPUNCT_FEATURE_DIR/package-helpers.sh"

mapfile -t packages < <(read_package_list "$DOCPUNCT_FEATURE_DIR/removable-packages.txt")
mapfile -t installed_packages < <(installed_packages "${packages[@]}")

if [[ "${#installed_packages[@]}" -gt 0 ]]; then
  sudo apt-get remove -y "${installed_packages[@]}"
fi
