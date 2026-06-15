#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=features/debian-gui-packages/package-helpers.sh
. "$DOCPUNCT_FEATURE_DIR/package-helpers.sh"

mapfile -t packages < <(read_package_list "$DOCPUNCT_FEATURE_DIR/packages.txt")
sudo apt-get update
sudo apt-get install -y "${packages[@]}"
