#!/usr/bin/env bash
set -euo pipefail

repo="git-ecosystem/git-credential-manager"
api_url="${DOCPUNCT_GCM_RELEASE_API_URL:-https://api.github.com/repos/$repo/releases/latest}"
download_dir="$DOCPUNCT_CACHE_DIR/downloads"
state_dir="$DOCPUNCT_STATE_DIR/debug-gcm-curl"
timestamp="$(date +%Y%m%d-%H%M%S)"
log_file="$DOCPUNCT_LOG_DIR/debug-gcm-curl-$timestamp.log"
latest_log="$DOCPUNCT_LOG_DIR/debug-gcm-curl-latest.log"
tmpdir="$(mktemp -d)"

cleanup() {
  rm -rf -- "$tmpdir"
}
trap cleanup EXIT

mkdir -p "$download_dir" "$state_dir" "$DOCPUNCT_LOG_DIR"
: >"$log_file"
ln -sfn -- "$log_file" "$latest_log"
printf '%s\n' "$log_file" >"$state_dir/latest-log"

log() {
  printf '%s\n' "$*" >>"$log_file"
}

redact() {
  sed -E \
    -e 's/(Authorization:[[:space:]]*)[^[:cntrl:]]+/\1<redacted>/Ig' \
    -e 's/(Proxy-Authorization:[[:space:]]*)[^[:cntrl:]]+/\1<redacted>/Ig' \
    -e 's/(Cookie:[[:space:]]*)[^[:cntrl:]]+/\1<redacted>/Ig' \
    -e 's#(https?://)[^/@[:space:]]+:[^/@[:space:]]+@#\1<redacted>@#Ig' \
    -e 's/([?&](access_token|token|auth|signature|sig)=)[^&[:space:]]+/\1<redacted>/Ig'
}

url_host() {
  local url="$1"
  url="${url#*://}"
  url="${url%%/*}"
  url="${url#*@}"
  printf '%s\n' "$url"
}

curl_fail_arg() {
  if curl --help all 2>/dev/null | grep -q -- '--fail-with-body'; then
    printf '%s\n' '--fail-with-body'
  else
    printf '%s\n' '--fail'
  fi
}

log_env_presence() {
  local name
  for name in HTTPS_PROXY HTTP_PROXY ALL_PROXY NO_PROXY https_proxy http_proxy all_proxy no_proxy; do
    if [[ -n "${!name:-}" ]]; then
      log "$name=<present redacted>"
    else
      log "$name=<unset>"
    fi
  done
  if [[ -n "${GITHUB_TOKEN:-${GH_TOKEN:-}}" ]]; then
    log "github_api_token=<present redacted>"
  else
    log "github_api_token=<unset>"
  fi
}

log_trace_file() {
  local label="$1" path="$2"
  log "--- sanitized $label ---"
  if [[ -s "$path" ]]; then
    redact <"$path" >>"$log_file"
  else
    log "<empty>"
  fi
}

run_curl_to_file() {
  local description="$1" url="$2" output="$3"
  local headers trace metrics stderr status fail_arg
  local -a auth_args=()
  headers="$tmpdir/${description//[^A-Za-z0-9_.-]/_}.headers"
  trace="$tmpdir/${description//[^A-Za-z0-9_.-]/_}.trace"
  metrics="$tmpdir/${description//[^A-Za-z0-9_.-]/_}.metrics"
  stderr="$tmpdir/${description//[^A-Za-z0-9_.-]/_}.stderr"
  fail_arg="$(curl_fail_arg)"

  log "stage=$description"
  log "url_host=$(url_host "$url")"
  log "url=$(printf '%s\n' "$url" | redact)"

  if [[ "$url" == https://api.github.com/* && -n "${GITHUB_TOKEN:-${GH_TOKEN:-}}" ]]; then
    auth_args=(-H "Authorization: Bearer ${GITHUB_TOKEN:-${GH_TOKEN:-}}")
  fi

  set +e
  if [[ "$url" == https://api.github.com/* ]]; then
    curl -L -sS "$fail_arg" \
      -A 'docpunct-debug-gcm-curl' \
      -H 'Accept: application/vnd.github+json' \
      "${auth_args[@]}" \
      -D "$headers" \
      --trace-ascii "$trace" \
      -w $'http_code=%{http_code}\neffective_url=%{url_effective}\nsize_download=%{size_download}\n' \
      -o "$output" \
      "$url" >"$metrics" 2>"$stderr"
  else
    curl -L -sS "$fail_arg" \
      -A 'docpunct-debug-gcm-curl' \
      -D "$headers" \
      --trace-ascii "$trace" \
      -w $'http_code=%{http_code}\neffective_url=%{url_effective}\nsize_download=%{size_download}\n' \
      -o "$output" \
      "$url" >"$metrics" 2>"$stderr"
  fi
  status="$?"
  set -e

  log "curl_exit=$status"
  log_trace_file "curl metrics" "$metrics"
  log_trace_file "curl stderr" "$stderr"
  log_trace_file "response headers" "$headers"
  log_trace_file "curl trace" "$trace"

  if [[ "$status" -ne 0 ]]; then
    printf 'debug-gcm-curl: %s failed; diagnostic log: %s\n' "$description" "$log_file" >&2
    return "$status"
  fi
}

require_command() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    log "missing required command: $command_name"
    printf 'debug-gcm-curl: missing required command: %s; diagnostic log: %s\n' "$command_name" "$log_file" >&2
    exit 1
  fi
}

require_command curl
require_command jq
require_command dpkg
require_command sha256sum

{
  log "debug-gcm-curl diagnostic started"
  log "timestamp_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  log "hostname=$(hostname 2>/dev/null || printf unknown)"
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    log "os=${PRETTY_NAME:-unknown}"
  else
    log "os=<unknown>"
  fi
  log "user=${USER:-unknown}"
  log "curl_version=$(curl --version | head -n 1)"
  log "jq_version=$(jq --version)"
  log_env_presence

  arch="$(dpkg --print-architecture)"
  case "$arch" in
    amd64) asset_arch="x64" ;;
    arm64) asset_arch="arm64" ;;
    *)
      log "unsupported_architecture=$arch"
      printf 'debug-gcm-curl: unsupported Debian architecture: %s; diagnostic log: %s\n' "$arch" "$log_file" >&2
      exit 1
      ;;
  esac
  log "debian_architecture=$arch"
  log "gcm_asset_architecture=$asset_arch"

  release_json_path="$tmpdir/release.json"
  run_curl_to_file "GitHub API release metadata" "$api_url" "$release_json_path"
  release_json="$(cat "$release_json_path")"
  tag="$(printf '%s\n' "$release_json" | jq -r '.tag_name')"
  log "release_tag=$tag"
  asset_record="$(
    printf '%s\n' "$release_json" |
      jq -r --arg arch "$asset_arch" '
        .assets[]
        | select(.name | test("^gcm-linux-" + $arch + "-.*\\.deb$"))
        | [.name, .browser_download_url, (.digest // "")]
        | @tsv
      ' |
      head -n 1
  )"
  IFS=$'\t' read -r asset_name asset_url asset_digest <<<"$asset_record"

  if [[ -z "$asset_url" || "$asset_url" == "null" ]]; then
    log "asset_selection=failed"
    log "available_assets:"
    printf '%s\n' "$release_json" | jq -r '.assets[].name' >>"$log_file"
    printf 'debug-gcm-curl: could not find GCM Linux %s asset; diagnostic log: %s\n' "$asset_arch" "$log_file" >&2
    exit 1
  fi

  log "asset_name=$asset_name"
  log "asset_url_host=$(url_host "$asset_url")"
  log "asset_digest=$asset_digest"

  package_path="$download_dir/debug-gcm-curl-$asset_name"
  run_curl_to_file "GitHub release asset download" "$asset_url" "$package_path"
  log "download_path=$package_path"

  if [[ "$asset_digest" =~ ^sha256:([[:xdigit:]]{64})$ ]]; then
    expected_sha256="${BASH_REMATCH[1]}"
    if printf '%s  %s\n' "$expected_sha256" "$package_path" | sha256sum --check --status -; then
      log "checksum=ok"
    else
      log "checksum=failed"
      printf 'debug-gcm-curl: checksum verification failed; diagnostic log: %s\n' "$log_file" >&2
      exit 1
    fi
  else
    log "checksum=skipped invalid_or_missing_digest"
  fi

  log "debug-gcm-curl diagnostic completed"
}

printf 'debug-gcm-curl diagnostic log: %s\n' "$log_file" >&2
