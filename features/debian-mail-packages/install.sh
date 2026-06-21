#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=features/debian-mail-packages/package-helpers.sh
. "$DOCPUNCT_FEATURE_DIR/package-helpers.sh"

mapfile -t packages < <(read_package_list "$DOCPUNCT_FEATURE_DIR/packages.txt")
sudo DEBIAN_FRONTEND=noninteractive apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"
"$DOCPUNCT_FEATURE_DIR/configure-apparmor.sh"
