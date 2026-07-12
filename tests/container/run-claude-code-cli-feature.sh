#!/usr/bin/env bash
set -euo pipefail

ubuntu_version="${1:-24.04}"
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
image="ubuntu:${ubuntu_version}"

case "$ubuntu_version" in
  22.04|24.04|26.04) ;;
  *)
    printf 'unsupported Ubuntu version: %s\n' "$ubuntu_version" >&2
    printf 'supported versions: 22.04, 24.04, 26.04\n' >&2
    exit 2
    ;;
esac

docker run --rm -i \
  --name "docpunct-claude-code-cli-feature-test-${ubuntu_version}" \
  -e DEBIAN_FRONTEND=noninteractive \
  -v "$repo_root:/workspace/docpunct:ro" \
  --workdir /workspace/docpunct \
  "$image" \
  bash /workspace/docpunct/tests/container/test-claude-code-cli-feature.sh
