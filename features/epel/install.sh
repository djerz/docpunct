#!/usr/bin/env bash
set -euo pipefail

bin_dir="$HOME/.local/bin"
private_bin_dir="$HOME/.local/lib/epel/bin"
systemd_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

mkdir -p "$bin_dir" "$private_bin_dir" "$systemd_dir"

install_link() {
  local source="$1" target="$2" current
  if [[ -L "$target" ]]; then
    current="$(readlink "$target")"
    if [[ "$current" == "$source" ]]; then
      return 0
    fi
    printf 'refusing to replace foreign symlink: %s -> %s\n' "$target" "$current" >&2
    exit 1
  elif [[ -e "$target" ]]; then
    printf 'refusing to replace existing path: %s\n' "$target" >&2
    exit 1
  fi
  ln -s -- "$source" "$target"
}

install_link "$DOCPUNCT_FEATURE_DIR/epel" "$bin_dir/epel"
install_link "$DOCPUNCT_FEATURE_DIR/msmtp-wrapper" "$private_bin_dir/msmtp"

for unit in epel-sync.service epel-sync.timer epel-backup.service; do
  install_link "$DOCPUNCT_FEATURE_DIR/$unit" "$systemd_dir/$unit"
done

systemctl --user daemon-reload >/dev/null 2>&1 || true
