#!/usr/bin/env bash
set -euo pipefail

mapfile -t packages < <(grep -Ev '^[[:space:]]*(#|$)' "$DOCPUNCT_FEATURE_DIR/packages.txt")
sudo apt-get remove -y "${packages[@]}"

