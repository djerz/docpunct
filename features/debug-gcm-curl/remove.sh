#!/usr/bin/env bash
set -euo pipefail

rm -f -- "$DOCPUNCT_LOG_DIR/debug-gcm-curl-latest.log"
rm -rf -- "$DOCPUNCT_STATE_DIR/debug-gcm-curl"
