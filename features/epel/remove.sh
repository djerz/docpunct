#!/usr/bin/env bash
set -euo pipefail

bin_link="$HOME/.local/bin/epel"
wrapper_link="$HOME/.local/lib/epel/bin/msmtp"
systemd_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

systemctl --user disable --now epel-sync.timer epel-backup.service >/dev/null 2>&1 || true

for path in "$bin_link" "$wrapper_link"; do
  if [[ -L "$path" && "$(readlink "$path")" == "$DOCPUNCT_FEATURE_DIR"/* ]]; then
    rm -- "$path"
  elif [[ -e "$path" || -L "$path" ]]; then
    printf 'leaving non-docpunct path untouched: %s\n' "$path"
  fi
done

for unit in epel-sync.service epel-sync.timer epel-backup.service; do
  path="$systemd_dir/$unit"
  if [[ -L "$path" && "$(readlink "$path")" == "$DOCPUNCT_FEATURE_DIR/$unit" ]]; then
    rm -- "$path"
  elif [[ -e "$path" || -L "$path" ]]; then
    printf 'leaving non-docpunct systemd unit untouched: %s\n' "$path"
  fi
done

systemctl --user daemon-reload >/dev/null 2>&1 || true

printf '%s\n' 'Preserved epel configuration, state, queue, Maildir, and backups.'
