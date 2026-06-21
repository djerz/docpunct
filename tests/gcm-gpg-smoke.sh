#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf -- "$tmpdir"' EXIT

assert_contains() {
  local haystack="$1" needle="$2"
  [[ "$haystack" == *"$needle"* ]] || {
    printf 'expected output to contain: %s\noutput was:\n%s\n' "$needle" "$haystack" >&2
    exit 1
  }
}

assert_fails_with() {
  local expected="$1"
  shift
  local output status
  set +e
  output="$("$@" 2>&1)"
  status="$?"
  set -e
  [[ "$status" -ne 0 ]] || {
    printf 'expected command to fail: %s\n' "$*" >&2
    exit 1
  }
  assert_contains "$output" "$expected"
}

assert_contains "$(cat "$repo_root/features/gcm-gpg/feature.yml")" "  - gpg"
if grep -q 'git-credential-manager' "$repo_root/features/core/feature.yml" "$repo_root/features/dotfiles/feature.yml"; then
  printf 'core and dotfiles must not depend on Git Credential Manager\n' >&2
  exit 1
fi
if grep -Eq '^[[:space:]]*helper[[:space:]]*=' "$repo_root/dotfiles/.gitconfig"; then
  printf 'base dotfiles must not configure a credential helper\n' >&2
  exit 1
fi

fake_bin="$tmpdir/bin"
test_home="$tmpdir/home"
migration_cache="$test_home/.cache/docpunct"
mkdir -p "$fake_bin" "$test_home/.password-store"

cat >"$fake_bin/pass" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat >"$fake_bin/gpg" <<'EOF'
#!/usr/bin/env bash
printf 'sec:::::::::::e:\n'
EOF
cat >"$fake_bin/git-credential-manager" <<'EOF'
#!/usr/bin/env bash
printf 'fake-gcm\n'
EOF
cat >"$fake_bin/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
config_file="$HOME/.fake-git-includes"
case "$*" in
  'config --global --get-all include.path')
    [[ -f "$config_file" ]] || exit 1
    cat "$config_file"
    ;;
  'config --global --add include.path '*)
    printf '%s\n' "${5:?missing include path}" >>"$config_file"
    ;;
  *)
    printf 'unexpected fake git invocation: %s\n' "$*" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$fake_bin/pass" "$fake_bin/gpg" "$fake_bin/git-credential-manager" "$fake_bin/git"

assert_fails_with \
  'pass is not initialized' \
  env HOME="$test_home" PATH="$fake_bin:$PATH" \
    DOCPUNCT_FEATURE_DIR="$repo_root/features/gpg" \
    "$repo_root/features/gpg/check-readiness.sh"

printf 'TEST-FINGERPRINT\n' >"$test_home/.password-store/.gpg-id"
env HOME="$test_home" PATH="$fake_bin:$PATH" \
  DOCPUNCT_FEATURE_DIR="$repo_root/features/gpg" \
  "$repo_root/features/gpg/check-readiness.sh"

env HOME="$test_home" PATH="$fake_bin:$PATH" \
  "$repo_root/features/gcm-gpg/configure.sh" >/dev/null

managed_config="$test_home/.config/docpunct/git-credential-manager.gitconfig"
[[ -f "$managed_config" ]] || {
  printf 'expected managed GCM Git configuration\n' >&2
  exit 1
}
assert_contains "$(cat "$managed_config")" 'credentialStore = gpg'
assert_contains "$(cat "$managed_config")" "helper = $fake_bin/git-credential-manager"
[[ "$(stat -c '%a' "$managed_config")" == 600 ]] || {
  printf 'expected managed GCM Git configuration mode 600\n' >&2
  exit 1
}
[[ "$(env HOME="$test_home" PATH="$fake_bin:$PATH" git config --global --get-all include.path)" == "$test_home/.config/docpunct/git-credential-manager.gitconfig" ]] || {
  printf 'expected managed GCM include in the global Git configuration\n' >&2
  exit 1
}

# Configuration is idempotent and does not duplicate the include.
env HOME="$test_home" PATH="$fake_bin:$PATH" \
  "$repo_root/features/gcm-gpg/configure.sh" >/dev/null
[[ "$(env HOME="$test_home" PATH="$fake_bin:$PATH" git config --global --get-all include.path | wc -l)" -eq 1 ]] || {
  printf 'expected exactly one managed GCM include\n' >&2
  exit 1
}

mkdir -p "$migration_cache/state/installed"
touch "$migration_cache/state/installed/git-credential-manager"
touch "$migration_cache/state/installed/gcm-gpg"

legacy_remove_output="$(
  env HOME="$test_home" PATH="$fake_bin:$PATH" \
    DOCPUNCT_CACHE_DIR="$migration_cache" \
    "$repo_root/features/git-credential-manager/remove.sh"
)"
assert_contains "$legacy_remove_output" 'Keeping the shared gcm package because gcm-gpg is installed.'

assert_fails_with \
  'Remove the legacy git-credential-manager feature before removing gcm-gpg.' \
  env HOME="$test_home" PATH="$fake_bin:$PATH" \
    DOCPUNCT_CACHE_DIR="$migration_cache" \
    "$repo_root/features/gcm-gpg/remove.sh"

rm -f "$migration_cache/state/installed/git-credential-manager"
remove_output="$(
  env HOME="$test_home" PATH="$fake_bin:$PATH" \
    DOCPUNCT_CACHE_DIR="$migration_cache" \
    "$repo_root/features/gcm-gpg/remove.sh"
)"
assert_contains "$remove_output" 'Keeping the pre-existing shared gcm package.'
[[ ! -e "$managed_config" ]] || {
  printf 'expected gcm-gpg removal to delete only its managed Git fragment\n' >&2
  exit 1
}

printf 'gcm-gpg smoke tests passed\n'
