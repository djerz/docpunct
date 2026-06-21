#!/usr/bin/env bash

read_package_list() {
  local path="$1"
  [[ -f "$path" ]] || return 0
  grep -Ev '^[[:space:]]*(#|$)' "$path"
}
