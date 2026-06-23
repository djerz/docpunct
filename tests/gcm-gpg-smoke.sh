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
if grep -Eq '^[[:space:]]*helper[[:space:]]*=' "$repo_root/dotfiles/.config/docpunct/gitconfig"; then
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
chmod +x "$fake_bin/pass" "$fake_bin/gpg" "$fake_bin/git-credential-manager"

assert_fails_with \
  'pass is not initialized' \
  env HOME="$test_home" PATH="$fake_bin:$PATH" \
    DOCPUNCT_FEATURE_DIR="$repo_root/features/gpg" \
    "$repo_root/features/gpg/check-readiness.sh"

printf 'TEST-FINGERPRINT\n' >"$test_home/.password-store/.gpg-id"
env HOME="$test_home" PATH="$fake_bin:$PATH" \
  DOCPUNCT_FEATURE_DIR="$repo_root/features/gpg" \
  "$repo_root/features/gpg/check-readiness.sh"

cat >"$test_home/.gitconfig" <<EOF
[include]
	path = $test_home/.config/docpunct/git-credential-manager.gitconfig
[user]
	name = Existing User
[credential]
	helper = store
EOF

env HOME="$test_home" PATH="$fake_bin:$PATH" \
  DOCPUNCT_CACHE_DIR="$migration_cache" \
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
[[ "$(grep -Fxc '# >>> docpunct gcm-gpg >>>' "$test_home/.gitconfig")" -eq 1 ]] || {
  printf 'expected one managed gcm-gpg block\n' >&2
  exit 1
}
assert_contains "$(cat "$test_home/.gitconfig")" 'helper = store'
mapfile -t helpers < <(env HOME="$test_home" PATH="$fake_bin:$PATH" \
  git config --global --includes --get-all credential.helper)
[[ "${#helpers[@]}" -eq 3 && "${helpers[0]}" == store && -z "${helpers[1]}" && "${helpers[2]}" == "$fake_bin/git-credential-manager" ]] || {
  printf 'expected the managed reset and GCM to be the only effective global helpers\n' >&2
  exit 1
}
last_config_line="$(grep -Ev '^[[:space:]]*$' "$test_home/.gitconfig" | tail -n 1)"
[[ "$last_config_line" == '# <<< docpunct gcm-gpg <<<' ]] || {
  printf 'expected the managed gcm-gpg block at the end of .gitconfig\n' >&2
  exit 1
}

# Configuration is idempotent and does not duplicate the marked block.
env HOME="$test_home" PATH="$fake_bin:$PATH" \
  DOCPUNCT_CACHE_DIR="$migration_cache" \
  "$repo_root/features/gcm-gpg/configure.sh" >/dev/null
[[ "$(grep -Fxc '# >>> docpunct gcm-gpg >>>' "$test_home/.gitconfig")" -eq 1 ]] || {
  printf 'expected exactly one managed gcm-gpg block\n' >&2
  exit 1
}

malformed_home="$tmpdir/malformed-home"
mkdir -p "$malformed_home"
printf '%s\n' '# >>> docpunct gcm-gpg >>>' >"$malformed_home/.gitconfig"
assert_fails_with \
  'markers are malformed or duplicated' \
  env HOME="$malformed_home" \
    "$repo_root/features/gcm-gpg/git-hooks.sh" install

legacy_remove_home="$tmpdir/legacy-remove-home"
mkdir -p "$legacy_remove_home"
cat >"$legacy_remove_home/.gitconfig" <<EOF
[include]
	path = $legacy_remove_home/.config/docpunct/git-credential-manager.gitconfig
[credential]
	helper = store
EOF
env HOME="$legacy_remove_home" "$repo_root/features/gcm-gpg/git-hooks.sh" remove
if grep -Fq 'git-credential-manager.gitconfig' "$legacy_remove_home/.gitconfig"; then
  printf 'expected removal to migrate the deprecated unmanaged include\n' >&2
  exit 1
fi
assert_contains "$(cat "$legacy_remove_home/.gitconfig")" 'helper = store'

mkdir -p "$migration_cache/state/installed"
touch "$migration_cache/state/installed/git-credential-manager"
touch "$migration_cache/state/installed/gcm-gpg"
remove_output="$(
  env HOME="$test_home" PATH="$fake_bin:$PATH" \
    DOCPUNCT_CACHE_DIR="$migration_cache" \
    "$repo_root/features/gcm-gpg/remove.sh"
)"
assert_contains "$remove_output" 'Keeping the pre-existing shared gcm package.'
[[ ! -e "$migration_cache/state/installed/git-credential-manager" ]] || {
  printf 'expected gcm-gpg removal to clean stale legacy feature marker\n' >&2
  exit 1
}
[[ ! -e "$managed_config" ]] || {
  printf 'expected gcm-gpg removal to delete only its managed Git fragment\n' >&2
  exit 1
}
if grep -Fq '# >>> docpunct gcm-gpg >>>' "$test_home/.gitconfig"; then
  printf 'expected gcm-gpg removal to delete its managed include block\n' >&2
  exit 1
fi
assert_contains "$(cat "$test_home/.gitconfig")" 'helper = store'

printf 'gcm-gpg smoke tests passed\n'
