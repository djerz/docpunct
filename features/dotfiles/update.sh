#!/usr/bin/env bash
set -euo pipefail

"$DOCPUNCT_FEATURE_DIR/reconcile.sh"
"$DOCPUNCT_FEATURE_DIR/shell-hooks.sh" install
"$DOCPUNCT_FEATURE_DIR/git-hooks.sh" install
