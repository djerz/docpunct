#!/usr/bin/env bash

read_package_list() {
  local path="$1"
  [[ -f "$path" ]] || return 0
  grep -Ev '^[[:space:]]*(#|$)' "$path"
}

available_optional_packages() {
  local package
  for package in "$@"; do
    if apt-cache show "$package" >/dev/null 2>&1; then
      printf '%s\n' "$package"
    else
      printf 'Skipping optional package unavailable on this Ubuntu release: %s\n' "$package" >&2
    fi
  done
}

installed_packages() {
  local package
  for package in "$@"; do
    if dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii '; then
      printf '%s\n' "$package"
    fi
  done
}
