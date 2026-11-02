#!/usr/bin/env bash

# The runner captures output, but debconf dialogs need a visible terminal.
run_gui_apt() {
  if [[ -t 0 ]]; then
    # Open the caller's terminal as the caller, before sudo starts.
    # shellcheck disable=SC2024
    sudo apt-get "$@" >/dev/tty 2>&1
  else
    sudo apt-get "$@"
  fi
}

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
