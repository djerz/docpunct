#!/usr/bin/env bash

read_package_list() {
  local path="$1"
  [[ -f "$path" ]] || return 0
  grep -Ev '^[[:space:]]*(#|$)' "$path"
}

installed_packages() {
  local package
  for package in "$@"; do
    if dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii '; then
      printf '%s\n' "$package"
    fi
  done
}
