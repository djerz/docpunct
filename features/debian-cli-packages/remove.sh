#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=features/debian-cli-packages/package-helpers.sh
. "$DOCPUNCT_FEATURE_DIR/package-helpers.sh"

mapfile -t packages < <(read_package_list "$DOCPUNCT_FEATURE_DIR/packages.txt")
mapfile -t optional_packages < <(read_package_list "$DOCPUNCT_FEATURE_DIR/optional-packages.txt")
mapfile -t installed_packages < <(installed_packages "${packages[@]}" "${optional_packages[@]}")

if [[ "${#installed_packages[@]}" -gt 0 ]]; then
  sudo apt-get remove -y "${installed_packages[@]}"
fi
