#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=features/debian-cli-packages/package-helpers.sh
. "$DOCPUNCT_FEATURE_DIR/package-helpers.sh"

mapfile -t packages < <(read_package_list "$DOCPUNCT_FEATURE_DIR/packages.txt")
mapfile -t optional_packages < <(read_package_list "$DOCPUNCT_FEATURE_DIR/optional-packages.txt")
sudo apt-get update
mapfile -t available_optional_packages < <(available_optional_packages "${optional_packages[@]}")
sudo apt-get install -y "${packages[@]}" "${available_optional_packages[@]}"
