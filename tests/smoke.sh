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

assert_not_contains() {
  local haystack="$1" needle="$2"
  [[ "$haystack" != *"$needle"* ]] || {
    printf 'expected output not to contain: %s\noutput was:\n%s\n' "$needle" "$haystack" >&2
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

notice_features="$tmpdir/notice-features"
write_feature "$notice_features" guided
printf 'install_notice: Install user-owned data using HOWTO.md.\n' >>"$notice_features/guided/feature.yml"
printf '# Guided setup\n' >"$notice_features/guided/HOWTO.md"
notice_output="$(DOCPUNCT_FEATURES_DIR="$notice_features" run_docpunct install guided)"
assert_contains "$notice_output" "Install user-owned data using HOWTO.md."
assert_contains "$notice_output" "$notice_features/guided/HOWTO.md"
DOCPUNCT_FEATURES_DIR="$notice_features" run_docpunct remove guided >/dev/null

list_output="$(run_docpunct list)"
assert_contains "$list_output" "core"
assert_contains "$list_output" "dotfiles"

status_output="$(run_docpunct status)"
assert_contains "$status_output" "available    core"

neovide_manifest="$(cat "$repo_root/features/neovide/feature.yml")"
assert_contains "$neovide_manifest" "  - nerdfonts"

debug_proxy_home="$tmpdir/debug-proxy-home"
debug_proxy_cache="$tmpdir/debug-proxy-cache"
debug_proxy_bin="$tmpdir/debug-proxy-bin"
mkdir -p "$debug_proxy_home" "$debug_proxy_cache" "$debug_proxy_bin"
cat >"$debug_proxy_bin/dpkg" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$*" == "--print-architecture" ]]; then
  printf 'amd64\n'
  exit 0
fi
exit 1
EOF
cat >"$debug_proxy_bin/jq" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
args="$*"
if [[ "${1:-}" == "--version" ]]; then
  printf 'jq-9.9.9\n'
elif [[ "$args" == *".tag_name"* ]]; then
  printf 'v9.9.9\n'
elif [[ "$args" == *".assets[].name"* ]]; then
  printf 'gcm-linux-x64-9.9.9.deb\n'
else
  digest="$(printf 'fake package\n' | sha256sum | awk '{print $1}')"
  printf 'gcm-linux-x64-9.9.9.deb\thttps://objects.example.invalid/gcm-linux-x64-9.9.9.deb?token=asset-secret\tsha256:%s\n' "$digest"
fi
EOF
cat >"$debug_proxy_bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--help" ]]; then
  printf ' --fail-with-body\n'
  exit 0
fi
if [[ "${1:-}" == "--version" ]]; then
  printf 'curl 9.9.9 fake\n'
  exit 0
fi

headers=""
trace=""
output=""
url=""
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -D)
      headers="$2"
      shift 2
      ;;
    --trace-ascii)
      trace="$2"
      shift 2
      ;;
    -w|-A|-H|-o)
      if [[ "$1" == "-o" ]]; then
        output="$2"
      fi
      shift 2
      ;;
    -*)
      shift
      ;;
    *)
      url="$1"
      shift
      ;;
  esac
done

printf 'HTTP/2 200\nset-cookie: private-cookie\n' >"$headers"
printf '=> Send header\nAuthorization: Bearer fake-token\nProxy-Authorization: Basic fake-proxy\nGET %s\n' "$url" >"$trace"
printf 'http_code=200\neffective_url=%s\nsize_download=13\n' "$url"

case "$url" in
  https://api.github.com/*)
    if [[ "${DEBUG_CORPO_PROXY_FAIL_STAGE:-}" == api ]]; then
      printf 'HTTP/2 403\n' >"$headers"
      printf 'curl: (22) The requested URL returned error: 403\n' >&2
      exit 22
    fi
    printf '{"tag_name":"v9.9.9","assets":[{"name":"gcm-linux-x64-9.9.9.deb","browser_download_url":"https://objects.example.invalid/gcm-linux-x64-9.9.9.deb?token=asset-secret","digest":"sha256:%s"}]}\n' \
      "$(printf 'fake package\n' | sha256sum | awk '{print $1}')" >"$output"
    ;;
  *)
    if [[ "${DEBUG_CORPO_PROXY_FAIL_STAGE:-}" == asset ]]; then
      printf 'HTTP/2 403\n' >"$headers"
      printf 'curl: (22) The requested URL returned error: 403\n' >&2
      exit 22
    fi
    printf 'fake package\n' >"$output"
    ;;
esac
EOF
chmod +x "$debug_proxy_bin/curl" "$debug_proxy_bin/dpkg" "$debug_proxy_bin/jq"

env \
  HOME="$debug_proxy_home" \
  PATH="$debug_proxy_bin:$PATH" \
  HTTPS_PROXY="http://proxy-user:proxy-pass@proxy.example.invalid:8080" \
  GITHUB_TOKEN="github-secret-token" \
  DOCPUNCT_ROOT="$repo_root" \
  DOCPUNCT_FEATURE_DIR="$repo_root/features/debug-corpo-proxy" \
  DOCPUNCT_CACHE_DIR="$debug_proxy_cache" \
  DOCPUNCT_STATE_DIR="$debug_proxy_cache/state" \
  DOCPUNCT_LOG_DIR="$debug_proxy_cache/log" \
  "$repo_root/features/debug-corpo-proxy/install.sh" >/dev/null 2>&1
debug_proxy_log="$debug_proxy_cache/log/debug-corpo-proxy-latest.log"
[[ -L "$debug_proxy_log" ]] || {
  printf 'expected debug-corpo-proxy to maintain a latest log symlink\n' >&2
  exit 1
}
debug_proxy_log_content="$(cat "$debug_proxy_log")"
assert_contains "$debug_proxy_log_content" "HTTPS_PROXY=<present redacted>"
assert_contains "$debug_proxy_log_content" "github_api_token=<present redacted>"
assert_contains "$debug_proxy_log_content" "checksum=ok"
assert_contains "$debug_proxy_log_content" "Authorization: <redacted>"
assert_contains "$debug_proxy_log_content" "Proxy-Authorization: <redacted>"
assert_contains "$debug_proxy_log_content" "token=<redacted>"
assert_not_contains "$debug_proxy_log_content" "proxy-pass"
assert_not_contains "$debug_proxy_log_content" "github-secret-token"
assert_not_contains "$debug_proxy_log_content" "asset-secret"

debug_proxy_fail_cache="$tmpdir/debug-proxy-fail-cache"
mkdir -p "$debug_proxy_fail_cache"
assert_fails_with \
  "GitHub API release metadata failed" \
  env \
    HOME="$debug_proxy_home" \
    PATH="$debug_proxy_bin:$PATH" \
    DEBUG_CORPO_PROXY_FAIL_STAGE=api \
    DOCPUNCT_ROOT="$repo_root" \
    DOCPUNCT_FEATURE_DIR="$repo_root/features/debug-corpo-proxy" \
    DOCPUNCT_CACHE_DIR="$debug_proxy_fail_cache" \
    DOCPUNCT_STATE_DIR="$debug_proxy_fail_cache/state" \
    DOCPUNCT_LOG_DIR="$debug_proxy_fail_cache/log" \
    "$repo_root/features/debug-corpo-proxy/install.sh"
assert_contains "$(cat "$debug_proxy_fail_cache/log/debug-corpo-proxy-latest.log")" "stage=GitHub API release metadata"

debug_proxy_asset_fail_cache="$tmpdir/debug-proxy-asset-fail-cache"
mkdir -p "$debug_proxy_asset_fail_cache"
assert_fails_with \
  "GitHub release asset download failed" \
  env \
    HOME="$debug_proxy_home" \
    PATH="$debug_proxy_bin:$PATH" \
    DEBUG_CORPO_PROXY_FAIL_STAGE=asset \
    DOCPUNCT_ROOT="$repo_root" \
    DOCPUNCT_FEATURE_DIR="$repo_root/features/debug-corpo-proxy" \
    DOCPUNCT_CACHE_DIR="$debug_proxy_asset_fail_cache" \
    DOCPUNCT_STATE_DIR="$debug_proxy_asset_fail_cache/state" \
    DOCPUNCT_LOG_DIR="$debug_proxy_asset_fail_cache/log" \
    "$repo_root/features/debug-corpo-proxy/install.sh"
assert_contains "$(cat "$debug_proxy_asset_fail_cache/log/debug-corpo-proxy-latest.log")" "stage=GitHub release asset download"

dotfiles_features="$tmpdir/dotfiles-features"
mkdir -p "$dotfiles_features/dotfiles"
printf 'description: Test dotfiles\n' >"$dotfiles_features/dotfiles/feature.yml"
printf '.config/docpunct/session-env.sh\n.config/docpunct/bash-ext.sh\n.config/nvim\n' >"$dotfiles_features/dotfiles/files.txt"
mkdir -p "$tmpdir/dotfiles/.config/nvim/lua/plugins"
printf 'vim config\n' >"$tmpdir/dotfiles/.config/nvim/init.lua"
printf 'plugin config\n' >"$tmpdir/dotfiles/.config/nvim/lua/plugins/init.lua"
ln -s "$repo_root/features/dotfiles/install.sh" "$dotfiles_features/dotfiles/install.sh"
ln -s "$repo_root/features/dotfiles/update.sh" "$dotfiles_features/dotfiles/update.sh"
ln -s "$repo_root/features/dotfiles/remove.sh" "$dotfiles_features/dotfiles/remove.sh"
ln -s "$repo_root/features/dotfiles/reconcile.sh" "$dotfiles_features/dotfiles/reconcile.sh"
ln -s "$repo_root/features/dotfiles/shell-hooks.sh" "$dotfiles_features/dotfiles/shell-hooks.sh"
ln -s "$repo_root/features/dotfiles/git-hooks.sh" "$dotfiles_features/dotfiles/git-hooks.sh"

printf 'host bashrc\n' >"$test_home/.bashrc"
printf 'host profile\n' >"$test_home/.profile"
printf '[user]\n    email = host@example.com\n' >"$test_home/.gitconfig"

DOCPUNCT_FEATURES_DIR="$dotfiles_features" run_docpunct install dotfiles >/dev/null
[[ -f "$test_home/.bashrc" && ! -L "$test_home/.bashrc" ]] || {
  printf 'expected dotfiles install to preserve .bashrc as a regular file\n' >&2
  exit 1
}
[[ -f "$test_home/.profile" && ! -L "$test_home/.profile" ]] || {
  printf 'expected dotfiles install to preserve .profile as a regular file\n' >&2
  exit 1
}
assert_contains "$(cat "$test_home/.bashrc")" "host bashrc"
assert_contains "$(cat "$test_home/.bashrc")" ". \"\$HOME/.config/docpunct/bash-ext.sh\""
assert_contains "$(cat "$test_home/.profile")" "host profile"
assert_contains "$(cat "$test_home/.profile")" ". \"\$HOME/.config/docpunct/session-env.sh\""
[[ -f "$test_home/.gitconfig" && ! -L "$test_home/.gitconfig" ]] || {
  printf 'expected dotfiles install to preserve .gitconfig as a regular file\n' >&2
  exit 1
}
assert_contains "$(cat "$test_home/.gitconfig")" '# >>> docpunct git setup >>>'
assert_contains "$(cat "$test_home/.gitconfig")" 'email = host@example.com'
[[ -L "$test_home/.config/docpunct/session-env.sh" ]] || {
  printf 'expected dotfiles install to link session-env.sh\n' >&2
  exit 1
}
[[ -L "$test_home/.config/docpunct/bash-ext.sh" ]] || {
  printf 'expected dotfiles install to link bash-ext.sh\n' >&2
  exit 1
}
[[ -L "$test_home/.config/nvim" ]] || {
  printf 'expected dotfiles install to create nvim directory symlink\n' >&2
  exit 1
}

DOCPUNCT_FEATURES_DIR="$dotfiles_features" run_docpunct relink >/dev/null
[[ "$(grep -Fc '# >>> docpunct shell setup >>>' "$test_home/.bashrc")" -eq 1 ]] || {
  printf 'expected relink to keep one .bashrc shell block\n' >&2
  exit 1
}
[[ "$(grep -Fc '# >>> docpunct git setup >>>' "$test_home/.gitconfig")" -eq 1 ]] || {
  printf 'expected relink to keep one .gitconfig block\n' >&2
  exit 1
}
printf '.config/docpunct/session-env.sh\n.config/docpunct/bash-ext.sh\n.config/nvim\n.config/docpunct/gitconfig\n' >"$dotfiles_features/dotfiles/files.txt"
DOCPUNCT_FEATURES_DIR="$dotfiles_features" run_docpunct update dotfiles >/dev/null
[[ -L "$test_home/.config/docpunct/gitconfig" ]] || {
  printf 'expected dotfiles update to link newly added git config fragment\n' >&2
  exit 1
}
[[ "$(env HOME="$test_home" git config --global --get user.email)" == "host@example.com" ]] || {
  printf 'expected host git setting to override the docpunct fragment\n' >&2
  exit 1
}
DOCPUNCT_FEATURES_DIR="$dotfiles_features" run_docpunct remove dotfiles >/dev/null
[[ "$(cat "$test_home/.bashrc")" == "host bashrc" ]] || {
  printf 'expected dotfiles remove to preserve original .bashrc content\n' >&2
  exit 1
}
[[ "$(cat "$test_home/.profile")" == "host profile" ]] || {
  printf 'expected dotfiles remove to preserve original .profile content\n' >&2
  exit 1
}
[[ "$(cat "$test_home/.gitconfig")" == $'[user]\n    email = host@example.com' ]] || {
  printf 'expected dotfiles remove to preserve original .gitconfig content\n' >&2
  exit 1
}
[[ ! -e "$test_home/.config/docpunct/gitconfig" ]] || {
  printf 'expected dotfiles remove to remove git config fragment symlink\n' >&2
  exit 1
}
[[ ! -e "$test_home/.config/docpunct/session-env.sh" ]] || {
  printf 'expected dotfiles remove to remove session-env.sh symlink\n' >&2
  exit 1
}
[[ ! -e "$test_home/.config/nvim" ]] || {
  printf 'expected dotfiles remove to remove nvim directory symlink\n' >&2
  exit 1
}

profile_home="$tmpdir/profile-home"
mkdir -p "$profile_home/.nvm/versions/node/v99.0.0/bin" "$profile_home/.cargo/bin" "$profile_home/.config/docpunct"
ln -s "$repo_root/dotfiles/.config/docpunct/session-env.sh" "$profile_home/.config/docpunct/session-env.sh"
ln -s "$repo_root/dotfiles/.config/docpunct/bash-ext.sh" "$profile_home/.config/docpunct/bash-ext.sh"
printf 'printf "fake node\\n"\n' >"$profile_home/.nvm/versions/node/v99.0.0/bin/node"
chmod +x "$profile_home/.nvm/versions/node/v99.0.0/bin/node"
cat >"$profile_home/.nvm/nvm.sh" <<'EOF'
#!/usr/bin/env sh
export PATH="$NVM_DIR/versions/node/v99.0.0/bin:$PATH"
EOF
cat >"$profile_home/.cargo/env" <<'EOF'
export PATH="$HOME/.cargo/bin:$PATH"
EOF
cat >"$profile_home/.nvm/bash_completion" <<'EOF'
BASH_EXT_COMPLETION=loaded
EOF
profile_node_path="$(
  env -i HOME="$profile_home" PATH=/usr/bin:/bin sh -c ". \"\$HOME/.config/docpunct/session-env.sh\"; command -v node"
)"
[[ "$profile_node_path" == "$profile_home/.nvm/versions/node/v99.0.0/bin/node" ]] || {
  printf 'expected .profile to make nvm node available on PATH, got: %s\n' "$profile_node_path" >&2
  exit 1
}
profile_gpg_tty="$(
  env -i HOME="$profile_home" PATH=/usr/bin:/bin sh -c ". \"\$HOME/.config/docpunct/session-env.sh\"; printf '%s' \"\${GPG_TTY-}\""
)"
[[ -z "$profile_gpg_tty" ]] || {
  printf 'expected non-tty session-env.sh source to leave GPG_TTY unset, got: %s\n' "$profile_gpg_tty" >&2
  exit 1
}
bash_ext_output="$(
  # shellcheck disable=SC2016
  env -i HOME="$profile_home" PATH=/usr/bin:/bin \
    bash --noprofile --norc -ic \
    '. "$HOME/.config/docpunct/bash-ext.sh"; alias ll; printf "completion=%s\n" "$BASH_EXT_COMPLETION"' \
    2>/dev/null
)"
assert_contains "$bash_ext_output" "alias ll='ls -alF'"
assert_contains "$bash_ext_output" "completion=loaded"

hook_test_home="$tmpdir/hook-test-home"
hook_test_cache="$tmpdir/hook-test-cache"
mkdir -p "$hook_test_home" "$hook_test_cache/backups/dotfiles"
printf 'foreign bashrc\n' >"$tmpdir/foreign-bashrc"
ln -s "$tmpdir/foreign-bashrc" "$hook_test_home/.bashrc"
assert_fails_with \
  "refusing to edit foreign shell symlink" \
  env \
    HOME="$hook_test_home" \
    DOCPUNCT_ROOT="$repo_root" \
    DOCPUNCT_DOTFILES_BACKUP_DIR="$hook_test_cache/backups/dotfiles" \
    "$repo_root/features/dotfiles/shell-hooks.sh" install
[[ "$(cat "$tmpdir/foreign-bashrc")" == "foreign bashrc" ]] || {
  printf 'expected foreign .bashrc symlink target to remain untouched\n' >&2
  exit 1
}

rm -- "$hook_test_home/.bashrc"
printf '%s\n%s\n%s\n%s\n' \
  '# >>> docpunct shell setup >>>' \
  '# >>> docpunct shell setup >>>' \
  '# <<< docpunct shell setup <<<' \
  '# <<< docpunct shell setup <<<' >"$hook_test_home/.profile"
assert_fails_with \
  "markers are malformed or duplicated" \
  env \
    HOME="$hook_test_home" \
    DOCPUNCT_ROOT="$repo_root" \
    DOCPUNCT_DOTFILES_BACKUP_DIR="$hook_test_cache/backups/dotfiles" \
    "$repo_root/features/dotfiles/shell-hooks.sh" install

rm -f -- "$hook_test_home/.gitconfig"
printf 'foreign gitconfig\n' >"$tmpdir/foreign-gitconfig"
ln -s "$tmpdir/foreign-gitconfig" "$hook_test_home/.gitconfig"
assert_fails_with \
  "refusing to edit foreign git config symlink" \
  env \
    HOME="$hook_test_home" \
    DOCPUNCT_ROOT="$repo_root" \
    DOCPUNCT_DOTFILES_BACKUP_DIR="$hook_test_cache/backups/dotfiles" \
    "$repo_root/features/dotfiles/git-hooks.sh" install

new_git_home="$tmpdir/new-git-home"
mkdir -p "$new_git_home"
env \
  HOME="$new_git_home" \
  DOCPUNCT_ROOT="$repo_root" \
  DOCPUNCT_DOTFILES_BACKUP_DIR="$hook_test_cache/backups/dotfiles" \
  "$repo_root/features/dotfiles/git-hooks.sh" install
[[ -f "$new_git_home/.gitconfig" && ! -L "$new_git_home/.gitconfig" ]] || {
  printf 'expected git hook install to create a regular .gitconfig\n' >&2
  exit 1
}
[[ "$(grep -Fc '# >>> docpunct git setup >>>' "$new_git_home/.gitconfig")" -eq 1 ]] || {
  printf 'expected new .gitconfig to contain one managed block\n' >&2
  exit 1
}
env \
  HOME="$new_git_home" \
  DOCPUNCT_ROOT="$repo_root" \
  DOCPUNCT_DOTFILES_BACKUP_DIR="$hook_test_cache/backups/dotfiles" \
  "$repo_root/features/dotfiles/git-hooks.sh" remove
[[ -f "$new_git_home/.gitconfig" && ! -s "$new_git_home/.gitconfig" ]] || {
  printf 'expected git hook removal to retain an empty regular .gitconfig\n' >&2
  exit 1
}
[[ "$(cat "$tmpdir/foreign-gitconfig")" == "foreign gitconfig" ]] || {
  printf 'expected foreign .gitconfig symlink target to remain untouched\n' >&2
  exit 1
}

rm -- "$hook_test_home/.gitconfig"
printf '%s\n%s\n%s\n%s\n' \
  '# >>> docpunct git setup >>>' \
  '# >>> docpunct git setup >>>' \
  '# <<< docpunct git setup <<<' \
  '# <<< docpunct git setup <<<' >"$hook_test_home/.gitconfig"
assert_fails_with \
  "markers are malformed or duplicated" \
  env \
    HOME="$hook_test_home" \
    DOCPUNCT_ROOT="$repo_root" \
    DOCPUNCT_DOTFILES_BACKUP_DIR="$hook_test_cache/backups/dotfiles" \
    "$repo_root/features/dotfiles/git-hooks.sh" install

migration_features="$tmpdir/migration-features"
migration_cache="$tmpdir/migration-cache"
migration_home="$tmpdir/migration-home"
mkdir -p "$migration_features/dotfiles" "$migration_home/.config/nvim/lua/plugins" "$migration_cache/state/installed"
printf 'description: Test dotfiles migration\n' >"$migration_features/dotfiles/feature.yml"
printf '.config/docpunct/session-env.sh\n.config/docpunct/bash-ext.sh\n.config/docpunct/gitconfig\n.config/nvim\n' >"$migration_features/dotfiles/files.txt"
ln -s "$repo_root/features/dotfiles/install.sh" "$migration_features/dotfiles/install.sh"
ln -s "$repo_root/features/dotfiles/update.sh" "$migration_features/dotfiles/update.sh"
ln -s "$repo_root/features/dotfiles/reconcile.sh" "$migration_features/dotfiles/reconcile.sh"
ln -s "$repo_root/features/dotfiles/shell-hooks.sh" "$migration_features/dotfiles/shell-hooks.sh"
ln -s "$repo_root/features/dotfiles/git-hooks.sh" "$migration_features/dotfiles/git-hooks.sh"
printf 'feature=dotfiles\n' >"$migration_cache/state/installed/dotfiles"
ln -s "$repo_root/dotfiles/.config/nvim/init.lua" "$migration_home/.config/nvim/init.lua"
ln -s "$repo_root/dotfiles/.config/nvim/lua/plugins/init.lua" "$migration_home/.config/nvim/lua/plugins/init.lua"
mkdir -p "$migration_cache/backups/dotfiles"
printf 'restored bashrc\n' >"$migration_cache/backups/dotfiles/.bashrc"
printf 'restored profile\n' >"$migration_cache/backups/dotfiles/.profile"
printf '[user]\n    email = restored@example.com\n' >"$migration_cache/backups/dotfiles/.gitconfig"
ln -s "$repo_root/dotfiles/.bashrc" "$migration_home/.bashrc"
ln -s "$repo_root/dotfiles/.profile" "$migration_home/.profile"
ln -s "$repo_root/dotfiles/.gitconfig" "$migration_home/.gitconfig"

env \
  HOME="$migration_home" \
  DOCPUNCT_FEATURES_DIR="$migration_features" \
  DOCPUNCT_CACHE_DIR="$migration_cache" \
  "$repo_root/bin/docpunct" update dotfiles >/dev/null
[[ -L "$migration_home/.config/nvim" ]] || {
  printf 'expected dotfiles update to replace nvim directory with directory symlink\n' >&2
  exit 1
}
[[ "$(readlink "$migration_home/.config/nvim")" == "$repo_root/dotfiles/.config/nvim" ]] || {
  printf 'expected nvim symlink to point at dotfiles nvim directory\n' >&2
  exit 1
}
[[ -L "$migration_cache/backups/dotfiles/.config/nvim/init.lua" ]] || {
  printf 'expected previous nvim directory to be preserved in dotfiles backup\n' >&2
  exit 1
}
[[ ! -L "$migration_home/.bashrc" ]] || {
  printf 'expected dotfiles update to migrate legacy .bashrc symlink\n' >&2
  exit 1
}
assert_contains "$(cat "$migration_home/.bashrc")" "restored bashrc"
assert_contains "$(cat "$migration_home/.bashrc")" ". \"\$HOME/.config/docpunct/bash-ext.sh\""
assert_contains "$(cat "$migration_home/.profile")" "restored profile"
[[ ! -L "$migration_home/.gitconfig" ]] || {
  printf 'expected dotfiles update to migrate legacy .gitconfig symlink\n' >&2
  exit 1
}
assert_contains "$(cat "$migration_home/.gitconfig")" "restored@example.com"
assert_contains "$(cat "$migration_home/.gitconfig")" '# >>> docpunct git setup >>>'
[[ "$(env HOME="$migration_home" git config --global --get user.email)" == "restored@example.com" ]] || {
  printf 'expected restored git setting to override the docpunct fragment\n' >&2
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
[[ -f "$neovide_home/.local/share/icons/docpunct/neovide.ico" ]] || {
  printf 'expected neovide install to copy desktop icon\n' >&2
  exit 1
}
assert_contains \
  "$(cat "$neovide_home/.local/share/applications/neovide.desktop")" \
  "Icon=$neovide_home/.local/share/icons/docpunct/neovide.ico"

nerdfonts_home="$tmpdir/nerdfonts-home"
nerdfonts_cache="$tmpdir/nerdfonts-cache"
nerdfonts_bin="$tmpdir/nerdfonts-bin"
nerdfonts_fc_log="$tmpdir/nerdfonts-fc-cache.log"
mkdir -p "$nerdfonts_home" "$nerdfonts_cache" "$nerdfonts_bin"
cat >"$nerdfonts_bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$*" == "-fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" ]]; then
  printf '{"tag_name":"v9.9.9","assets":[]}\n'
  exit 0
fi

output=""
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -o)
      output="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done
[[ -n "$output" ]] || exit 1
if [[ "$output" == */SHA-256.txt ]]; then
  if [[ "${NERDFONTS_BAD_CHECKSUM:-0}" == "1" ]]; then
    checksum="0000000000000000000000000000000000000000000000000000000000000000"
  else
    checksum="$(printf 'fake archive\n' | sha256sum | awk '{print $1}')"
  fi
  for name in JetBrainsMono.zip Hack.zip FiraCode.zip SourceCodePro.zip Noto.zip; do
    printf '%s  %s\n' "$checksum" "$name"
  done >"$output"
else
  printf 'fake archive\n' >"$output"
fi
EOF
cat >"$nerdfonts_bin/jq" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$*" == *".tag_name"* ]]; then
  printf 'v9.9.9\n'
elif [[ "$*" == *'select(.name == "SHA-256.txt")'* ]]; then
  printf 'https://example.invalid/SHA-256.txt\n'
elif [[ "$*" == *"--arg name"* ]]; then
  name=""
  while [[ "$#" -gt 0 ]]; do
    if [[ "$1" == "--arg" && "${2:-}" == "name" ]]; then
      name="$3"
      break
    fi
    shift
  done
  printf 'https://example.invalid/%s\n' "$name"
else
  printf 'JetBrainsMono.zip\nHack.zip\nFiraCode.zip\nSourceCodePro.zip\nNoto.zip\n'
fi
EOF
cat >"$nerdfonts_bin/unzip" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
archive=""
dest=""
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -d)
      dest="$2"
      shift 2
      ;;
    -*)
      shift
      ;;
    *)
      archive="$1"
      shift
      ;;
  esac
done
[[ -n "$archive" && -n "$dest" ]] || exit 1
mkdir -p "$dest"
base="$(basename "$archive" .zip)"
printf 'fake font\n' >"$dest/$base Nerd Font Complete.ttf"
EOF
cat >"$nerdfonts_bin/fc-cache" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$NERDFONTS_FC_LOG"
EOF
chmod +x "$nerdfonts_bin/curl" "$nerdfonts_bin/jq" "$nerdfonts_bin/unzip" "$nerdfonts_bin/fc-cache"

env \
  HOME="$nerdfonts_home" \
  PATH="$nerdfonts_bin:$PATH" \
  DOCPUNCT_CACHE_DIR="$nerdfonts_cache" \
  DOCPUNCT_FEATURE_DIR="$repo_root/features/nerdfonts" \
  NERDFONTS_FC_LOG="$nerdfonts_fc_log" \
  "$repo_root/features/nerdfonts/install.sh"
for font_asset in JetBrainsMono Hack FiraCode SourceCodePro Noto; do
  [[ -f "$nerdfonts_home/.local/share/fonts/docpunct/nerdfonts/$font_asset Nerd Font Complete.ttf" ]] || {
    printf 'expected nerdfonts install to install font from asset: %s\n' "$font_asset" >&2
    exit 1
  }
done
assert_contains "$(cat "$nerdfonts_fc_log")" "-f $nerdfonts_home/.local/share/fonts"

if env \
  HOME="$nerdfonts_home" \
  PATH="$nerdfonts_bin:$PATH" \
  DOCPUNCT_CACHE_DIR="$nerdfonts_cache" \
  DOCPUNCT_FEATURE_DIR="$repo_root/features/nerdfonts" \
  NERDFONTS_FC_LOG="$nerdfonts_fc_log" \
  NERDFONTS_BAD_CHECKSUM=1 \
  "$repo_root/features/nerdfonts/install.sh" 2>/dev/null; then
  printf 'expected nerdfonts install to reject an invalid archive checksum\n' >&2
  exit 1
fi

env \
  HOME="$nerdfonts_home" \
  PATH="$nerdfonts_bin:$PATH" \
  DOCPUNCT_FEATURE_DIR="$repo_root/features/nerdfonts" \
  NERDFONTS_FC_LOG="$nerdfonts_fc_log" \
  "$repo_root/features/nerdfonts/remove.sh"
[[ ! -e "$nerdfonts_home/.local/share/fonts/docpunct/nerdfonts" ]] || {
  printf 'expected nerdfonts remove to delete docpunct-owned font directory\n' >&2
  exit 1
}

fake_features="$tmpdir/features"
write_feature "$fake_features" base
write_feature "$fake_features" child base
write_feature "$fake_features" grandchild child
write_feature "$fake_features" cycle-a cycle-b
write_feature "$fake_features" cycle-b cycle-a

fake_cache="$tmpdir/fake-cache"
mkdir -p "$fake_cache/state/installed"
DOCPUNCT_FEATURES_DIR="$fake_features" DOCPUNCT_CACHE_DIR="$fake_cache" "$repo_root/bin/docpunct" install child >/dev/null

write_feature "$fake_features" installed-parent missing-dependency
printf 'feature=installed-parent\n' >"$fake_cache/state/installed/installed-parent"
installed_output="$(
  DOCPUNCT_FEATURES_DIR="$fake_features" \
    DOCPUNCT_CACHE_DIR="$fake_cache" \
    "$repo_root/bin/docpunct" install installed-parent
)"
assert_contains "$installed_output" "installed-parent already installed"

assert_fails_with \
  "cannot remove base; installed feature(s) depend on it: child" \
  env DOCPUNCT_FEATURES_DIR="$fake_features" DOCPUNCT_CACHE_DIR="$fake_cache" "$repo_root/bin/docpunct" remove base

update_cache="$tmpdir/update-cache"
mkdir -p "$update_cache/state/installed"
printf 'feature=child\n' >"$update_cache/state/installed/child"

update_output="$(
  env DOCPUNCT_FEATURES_DIR="$fake_features" DOCPUNCT_CACHE_DIR="$update_cache" \
    "$repo_root/bin/docpunct" update child
)"
assert_contains "$update_output" "docpunct install base"
assert_contains "$update_output" "Updating child"
[[ ! -f "$update_cache/state/installed/base" ]] || {
  printf 'expected update not to install a newly introduced dependency\n' >&2
  exit 1
}

printf 'feature=grandchild\n' >"$update_cache/state/installed/grandchild"
grandchild_update_output="$(
  env DOCPUNCT_FEATURES_DIR="$fake_features" DOCPUNCT_CACHE_DIR="$update_cache" \
    "$repo_root/bin/docpunct" update grandchild
)"
assert_contains \
  "$grandchild_update_output" \
  $'docpunct install base\n  docpunct update child'
assert_not_contains "$grandchild_update_output" "Updating child"
[[ ! -f "$update_cache/state/installed/base" ]] || {
  printf 'expected transitive dependency guidance not to install base\n' >&2
  exit 1
}

assert_fails_with \
  "not installed: base" \
  env DOCPUNCT_FEATURES_DIR="$fake_features" DOCPUNCT_CACHE_DIR="$update_cache" \
    "$repo_root/bin/docpunct" update base

assert_fails_with \
  "dependency cycle detected" \
  env DOCPUNCT_FEATURES_DIR="$fake_features" DOCPUNCT_CACHE_DIR="$tmpdir/cycle-cache" "$repo_root/bin/docpunct" install cycle-a

rollback_features="$tmpdir/rollback-features"
rollback_cache="$tmpdir/rollback-cache"
rollback_artifact="$tmpdir/rollback-artifact"
write_feature "$rollback_features" failing-install
cat >"$rollback_features/failing-install/install.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
touch "$rollback_artifact"
exit 1
EOF
cat >"$rollback_features/failing-install/remove.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
rm -f -- "$rollback_artifact"
EOF
chmod +x \
  "$rollback_features/failing-install/install.sh" \
  "$rollback_features/failing-install/remove.sh"

assert_fails_with \
  "Cleaning up failed install: failing-install" \
  env DOCPUNCT_FEATURES_DIR="$rollback_features" DOCPUNCT_CACHE_DIR="$rollback_cache" "$repo_root/bin/docpunct" install failing-install
[[ ! -e "$rollback_artifact" ]] || {
  printf 'expected failed install rollback to remove its artifact\n' >&2
  exit 1
}
[[ ! -e "$rollback_cache/state/installed/failing-install" ]] || {
  printf 'expected failed install to remain unmarked\n' >&2
  exit 1
}
compgen -G "$rollback_cache/log/*-install-failing-install.log" >/dev/null || {
  printf 'expected failed install to retain its error log\n' >&2
  exit 1
}

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

gui_remove_bin="$tmpdir/gui-remove-bin"
gui_remove_log="$tmpdir/gui-remove-apt.log"
mkdir -p "$gui_remove_bin"
cat >"$gui_remove_bin/dpkg-query" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
package="${@: -1}"
case "$package" in
  keepassxc|meld|desktop-file-utils|gnome-icon-theme|adwaita-icon-theme-full|gnome-calendar|gnome-contacts|seahorse|gnome-keyring|libpam-gnome-keyring|libsecret-tools|dbus-user-session|libfontconfig1-dev|libfreetype6-dev|wl-clipboard|xclip)
    printf 'ii '
    ;;
  *)
    exit 1
    ;;
esac
EOF
cat >"$gui_remove_bin/sudo" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
"$@"
EOF
cat >"$gui_remove_bin/apt-get" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$GUI_REMOVE_LOG"
EOF
chmod +x "$gui_remove_bin/dpkg-query" "$gui_remove_bin/sudo" "$gui_remove_bin/apt-get"

env \
  PATH="$gui_remove_bin:$PATH" \
  GUI_REMOVE_LOG="$gui_remove_log" \
  DOCPUNCT_FEATURE_DIR="$repo_root/features/debian-gui-packages" \
  "$repo_root/features/debian-gui-packages/remove.sh"
gui_remove_output="$(cat "$gui_remove_log")"
assert_contains "$gui_remove_output" "remove -y keepassxc meld"
for protected_package in desktop-file-utils gnome-icon-theme adwaita-icon-theme-full gnome-calendar gnome-contacts seahorse gnome-keyring libpam-gnome-keyring libsecret-tools dbus-user-session libfontconfig1-dev libfreetype6-dev wl-clipboard xclip ubuntu-desktop ubuntu-desktop-minimal gdm3 gnome-control-center nautilus; do
  if [[ "$gui_remove_output" == *"$protected_package"* ]]; then
    printf 'expected debian-gui-packages remove not to include protected/shared package: %s\noutput was:\n%s\n' "$protected_package" "$gui_remove_output" >&2
    exit 1
  fi
done

"$repo_root/tests/epel-smoke.sh"
"$repo_root/tests/gcm-gpg-smoke.sh"
"$repo_root/tests/ollama-smoke.sh"

printf 'smoke tests passed\n'
