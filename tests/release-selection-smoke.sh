#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf -- "$tmpdir"' EXIT
export HOME="$tmpdir/home" PATH="$tmpdir/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
export RELEASE_TEST_LOG="$tmpdir/calls"
mkdir -p "$HOME/.nvm" "$HOME/.local/bin" "$tmpdir/bin"

cat >"$tmpdir/bin/curl" <<'MOCK'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >>"$RELEASE_TEST_LOG"
case "$*" in
  *api.github.com/repos/nvm-sh/nvm/releases/latest*)
    printf '{"tag_name":"%s"}\n' "${RELEASE_TEST_TAG:-v99.8.7}" ;;
  *raw.githubusercontent.com/nvm-sh/nvm/v99.8.7/install.sh*)
    printf 'test "$PROFILE" = /dev/null\n' ;;
  *play0ad.com/download/linux/*)
    printf '<a href="https://releases.wildfiregames.com/0ad-99.8.7-x86_64.AppImage">Download</a>\n' ;;
  *0ad-99.8.7-x86_64.AppImage.sha256sum*)
    cp "$RELEASE_TEST_FIXTURE.sha256sum" "${@: -1}" ;;
  *0ad-99.8.7-x86_64.AppImage*)
    cp "$RELEASE_TEST_FIXTURE" "${@: -1}" ;;
  *) exit 1 ;;
esac
MOCK
cat >"$HOME/.nvm/nvm.sh" <<'MOCK'
nvm() {
  printf 'nvm %s\n' "$*" >>"$RELEASE_TEST_LOG"
  case "$*" in
    'version default')
      printf '%s\n' "${RELEASE_TEST_DEFAULT:-v24.1.0}"
      [[ "${RELEASE_TEST_DEFAULT:-v24.1.0}" != N/A ]] ;;
    'version node')
      printf '%s\n' "${RELEASE_TEST_LOCAL:-v24.2.0}"
      [[ "${RELEASE_TEST_LOCAL:-v24.2.0}" != N/A ]] ;;
    current) printf 'v99.8.7\n' ;;
    'reinstall-packages v24.1.0'|'reinstall-packages v24.2.0') ;;
    reinstall-packages*) return 5 ;;
  esac
}
MOCK
chmod +x "$tmpdir/bin/curl"
for action in install update; do
  "$repo_root/features/node/$action.sh"
done
grep -Fqx 'nvm install node' "$RELEASE_TEST_LOG"
grep -Fqx 'nvm reinstall-packages v24.1.0' "$RELEASE_TEST_LOG"
grep -Fqx 'nvm alias default node' "$RELEASE_TEST_LOG"
# A stale default falls back to the newest locally installed Node.
: >"$RELEASE_TEST_LOG"
RELEASE_TEST_DEFAULT=N/A "$repo_root/features/node/update.sh"
grep -Fqx 'nvm reinstall-packages v24.2.0' "$RELEASE_TEST_LOG"
# A repeat update and a machine with no installed Node need no migration.
for scenario in same missing; do
  : >"$RELEASE_TEST_LOG"
  if [[ "$scenario" == same ]]; then
    RELEASE_TEST_DEFAULT=v99.8.7 "$repo_root/features/node/update.sh"
  else
    RELEASE_TEST_DEFAULT=N/A RELEASE_TEST_LOCAL=N/A "$repo_root/features/node/update.sh"
  fi
  grep -Fqx 'nvm install node' "$RELEASE_TEST_LOG"
  grep -Fqx 'nvm alias default node' "$RELEASE_TEST_LOG"
  if grep -q '^nvm reinstall-packages ' "$RELEASE_TEST_LOG"; then
    printf 'unexpected package migration for %s scenario\n' "$scenario" >&2
    exit 1
  fi
done
for tag in null v99.8.7-rc1; do
  if RELEASE_TEST_TAG="$tag" "$repo_root/features/node/update.sh" >/dev/null 2>&1; then
    printf 'expected invalid NVM release to fail: %s\n' "$tag" >&2
    exit 1
  fi
done

cat >"$HOME/.local/bin/uv" <<'MOCK'
#!/usr/bin/env bash
exit 42
MOCK
chmod +x "$HOME/.local/bin/uv"
if DOCPUNCT_STATE_DIR="$tmpdir/state" "$repo_root/features/python-uv/install.sh"; then
  printf 'expected uv self-update failure to propagate\n' >&2
  exit 1
fi
test ! -e "$tmpdir/state/python-uv/owned-by-docpunct"

cat >"$tmpdir/bin/dpkg" <<'MOCK'
#!/usr/bin/env bash
printf 'amd64\n'
MOCK
cat >"$tmpdir/bin/dpkg-query" <<'MOCK'
#!/usr/bin/env bash
printf 'ii \n'
MOCK
chmod +x "$tmpdir/bin/dpkg" "$tmpdir/bin/dpkg-query"
export RELEASE_TEST_FIXTURE="$tmpdir/0ad-99.8.7-x86_64.AppImage"
cat >"$RELEASE_TEST_FIXTURE" <<'MOCK'
#!/usr/bin/env bash
if [[ "${1:-}" == --appimage-extract ]]; then exit 1; fi
printf 'fixture release 99.8.7\n'
MOCK
(cd "$tmpdir" && sha256sum 0ad-99.8.7-x86_64.AppImage >"$RELEASE_TEST_FIXTURE.sha256sum")
export DOCPUNCT_CACHE_DIR="$tmpdir/cache"
export DOCPUNCT_FEATURE_DIR="$repo_root/features/zero-ad"
export DOCPUNCT_ZERO_AD_SKIP_FUSE_PACKAGE=1
unset DOCPUNCT_ZERO_AD_VERSION
for action in install update; do
  "$repo_root/features/zero-ad/$action.sh"
  test "$("$HOME/.local/bin/0ad")" = 'fixture release 99.8.7'
done
if DOCPUNCT_ZERO_AD_VERSION=../invalid "$repo_root/features/zero-ad/install.sh" >/dev/null 2>&1; then
  printf 'expected invalid 0 A.D. version to fail\n' >&2
  exit 1
fi
printf 'release selection smoke tests passed\n'
