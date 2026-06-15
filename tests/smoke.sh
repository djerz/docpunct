#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf -- "$tmpdir"' EXIT

test_home="$tmpdir/home"
test_cache="$tmpdir/cache"
mkdir -p "$test_home" "$test_cache"

run_docpunct() {
  local env_args=(
    HOME="$test_home"
    DOCPUNCT_CACHE_DIR="$test_cache"
  )
  if [[ -n "${DOCPUNCT_FEATURES_DIR:-}" ]]; then
    env_args+=(DOCPUNCT_FEATURES_DIR="$DOCPUNCT_FEATURES_DIR")
  fi
  env "${env_args[@]}" "$repo_root/bin/docpunct" "$@"
}

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

  if [[ "$status" -eq 0 ]]; then
    printf 'expected command to fail: %s\n' "$*" >&2
    exit 1
  fi
  assert_contains "$output" "$expected"
}

write_feature() {
  local features_dir="$1" feature="$2" depends="${3:-}"
  mkdir -p "$features_dir/$feature"
  {
    printf 'description: Test feature %s\n' "$feature"
    if [[ -n "$depends" ]]; then
      printf 'depends:\n'
      local dep deps
      read -r -a deps <<<"$depends"
      for dep in "${deps[@]}"; do
        printf '  - %s\n' "$dep"
      done
    fi
  } >"$features_dir/$feature/feature.yml"
}

list_output="$(run_docpunct list)"
assert_contains "$list_output" "core"
assert_contains "$list_output" "dotfiles"

status_output="$(run_docpunct status)"
assert_contains "$status_output" "available    core"

dotfiles_features="$tmpdir/dotfiles-features"
mkdir -p "$dotfiles_features/dotfiles"
printf 'description: Test dotfiles\n' >"$dotfiles_features/dotfiles/feature.yml"
printf '.bashrc\n' >"$dotfiles_features/dotfiles/files.txt"
ln -s "$repo_root/features/dotfiles/install.sh" "$dotfiles_features/dotfiles/install.sh"
ln -s "$repo_root/features/dotfiles/remove.sh" "$dotfiles_features/dotfiles/remove.sh"

DOCPUNCT_FEATURES_DIR="$dotfiles_features" run_docpunct install dotfiles >/dev/null
[[ -L "$test_home/.bashrc" ]] || {
  printf 'expected dotfiles install to create .bashrc symlink\n' >&2
  exit 1
}

DOCPUNCT_FEATURES_DIR="$dotfiles_features" run_docpunct relink >/dev/null
DOCPUNCT_FEATURES_DIR="$dotfiles_features" run_docpunct remove dotfiles >/dev/null
[[ ! -e "$test_home/.bashrc" ]] || {
  printf 'expected dotfiles remove to remove .bashrc symlink\n' >&2
  exit 1
}

neovide_home="$tmpdir/neovide-home"
mkdir -p "$neovide_home/.cargo/bin"
cat >"$neovide_home/.cargo/env" <<'EOF'
export PATH="$HOME/.cargo/bin:$PATH"
EOF
cat >"$neovide_home/.cargo/bin/cargo" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >"$HOME/cargo-args"
EOF
chmod +x "$neovide_home/.cargo/bin/cargo"
env \
  HOME="$neovide_home" \
  DOCPUNCT_FEATURE_DIR="$repo_root/features/neovide" \
  "$repo_root/features/neovide/install.sh"
[[ "$(cat "$neovide_home/cargo-args")" == "install --locked neovide" ]] || {
  printf 'expected neovide install to use cargo from .cargo/env\n' >&2
  exit 1
}
[[ -f "$neovide_home/.local/share/applications/neovide.desktop" ]] || {
  printf 'expected neovide install to write desktop entry\n' >&2
  exit 1
}

fake_features="$tmpdir/features"
write_feature "$fake_features" base
write_feature "$fake_features" child base
write_feature "$fake_features" cycle-a cycle-b
write_feature "$fake_features" cycle-b cycle-a

fake_cache="$tmpdir/fake-cache"
mkdir -p "$fake_cache/state/installed"
DOCPUNCT_FEATURES_DIR="$fake_features" DOCPUNCT_CACHE_DIR="$fake_cache" "$repo_root/bin/docpunct" install child >/dev/null

assert_fails_with \
  "cannot remove base; installed feature(s) depend on it: child" \
  env DOCPUNCT_FEATURES_DIR="$fake_features" DOCPUNCT_CACHE_DIR="$fake_cache" "$repo_root/bin/docpunct" remove base

update_cache="$tmpdir/update-cache"
mkdir -p "$update_cache/state/installed"
printf 'feature=child\n' >"$update_cache/state/installed/child"

assert_fails_with \
  "not installed: base" \
  env DOCPUNCT_FEATURES_DIR="$fake_features" DOCPUNCT_CACHE_DIR="$update_cache" "$repo_root/bin/docpunct" update child

assert_fails_with \
  "dependency cycle detected" \
  env DOCPUNCT_FEATURES_DIR="$fake_features" DOCPUNCT_CACHE_DIR="$tmpdir/cycle-cache" "$repo_root/bin/docpunct" install cycle-a

stdin_features="$tmpdir/stdin-features"
write_feature "$stdin_features" stdin-parent "stdin-reader stdin-sibling"
write_feature "$stdin_features" stdin-reader
write_feature "$stdin_features" stdin-sibling
cat >"$stdin_features/stdin-reader/install.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cat >/dev/null || true
EOF
chmod +x "$stdin_features/stdin-reader/install.sh"

stdin_cache="$tmpdir/stdin-cache"
DOCPUNCT_FEATURES_DIR="$stdin_features" DOCPUNCT_CACHE_DIR="$stdin_cache" "$repo_root/bin/docpunct" install stdin-parent >/dev/null
[[ -f "$stdin_cache/state/installed/stdin-reader" ]] || {
  printf 'expected stdin-reader dependency to be installed\n' >&2
  exit 1
}
[[ -f "$stdin_cache/state/installed/stdin-sibling" ]] || {
  printf 'expected stdin-sibling dependency to be installed after stdin-consuming script\n' >&2
  exit 1
}

printf 'smoke tests passed\n'
