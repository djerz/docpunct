#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf -- "$tmpdir"' EXIT

test_home="$tmpdir/home"
fake_bin="$tmpdir/bin"
command_log="$tmpdir/commands.log"
mkdir -p "$test_home" "$fake_bin"

cat >"$fake_bin/mbsync" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'mbsync %s\n' "$*" >>"$EPEL_TEST_COMMAND_LOG"
[[ "${EPEL_TEST_FAIL_SYNC:-0}" != 1 ]]
EOF

cat >"$fake_bin/notmuch" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'notmuch %s\n' "$*" >>"$EPEL_TEST_COMMAND_LOG"
EOF

cat >"$fake_bin/msmtp" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'msmtp %s\n' "$*" >>"$EPEL_TEST_COMMAND_LOG"
cat >>"$EPEL_TEST_COMMAND_LOG"
printf '%s\n' '-- message end --' >>"$EPEL_TEST_COMMAND_LOG"
[[ "${EPEL_TEST_FAIL_SEND:-0}" != 1 ]]
EOF

cat >"$fake_bin/rsync" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
source_path="${@: -2:1}"
destination="${@: -1}"
printf 'rsync %s\n' "$*" >>"$EPEL_TEST_COMMAND_LOG"
cp -a -- "$source_path". "$destination"
EOF

cat >"$fake_bin/systemctl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'systemctl %s\n' "$*" >>"$EPEL_TEST_COMMAND_LOG"
if [[ "$*" == *'is-enabled'* ]]; then
  printf 'disabled\n'
fi
EOF

chmod +x "$fake_bin/mbsync" "$fake_bin/notmuch" "$fake_bin/msmtp" "$fake_bin/rsync" "$fake_bin/systemctl"

run_epel() {
  env \
    HOME="$test_home" \
    PATH="$fake_bin:/usr/bin:/bin" \
    EPEL_TEST_COMMAND_LOG="$command_log" \
    EPEL_MSMTP_BIN="$fake_bin/msmtp" \
    EPEL_SYSTEMCTL_BIN="$fake_bin/systemctl" \
    "$repo_root/features/epel/epel" "$@"
}

message() {
  local sender="$1" subject="$2"
  printf 'From: Test User <%s>\nTo: receiver@example.net\nSubject: %s\n\nbody\n' "$sender" "$subject"
}

config_output="$(run_epel config)"
grep -Fq 'notmuch new.ignore:     .mbsyncstate and .uidvalidity' <<<"$config_output"
grep -Fqx 'ignore=.mbsyncstate;.uidvalidity' "$repo_root/features/epel/HOWTO.md"

run_epel sync
grep -qx 'mbsync --all' "$command_log"
grep -qx 'notmuch new' "$command_log"
[[ -f "$test_home/.local/state/epel/last-sync" ]]

if run_epel fsync >/dev/null 2>"$tmpdir/fsync-missing.err"; then
  printf 'expected fsync without configured targets to fail\n' >&2
  exit 1
fi
grep -Fq 'fast sync targets are not configured' "$tmpdir/fsync-missing.err"

mkdir -p "$test_home/.config/epel"
cat >"$test_home/.config/epel/config" <<'EOF'
EPEL_FAST_SYNC_TARGETS=(
  "personal@example.com:INBOX"
  "work@example.org:INBOX"
)
EOF
run_epel fsync
grep -qx 'mbsync personal@example.com:INBOX' "$command_log"
grep -qx 'mbsync work@example.org:INBOX' "$command_log"
[[ -f "$test_home/.local/state/epel/last-fsync" ]]

run_epel send-queued
message first@example.com first | run_epel submit >/dev/null
message second@example.com second | run_epel submit >/dev/null
[[ "$(find "$test_home/.local/share/epel/queue" -type f -name '*.eml' | wc -l)" -eq 2 ]]
run_epel send >/dev/null
[[ "$(find "$test_home/.local/share/epel/queue" -type f -name '*.eml' | wc -l)" -eq 0 ]]
grep -q 'msmtp --account=first@example.com -t --read-envelope-from' "$command_log"
grep -q 'msmtp --account=second@example.com -t --read-envelope-from' "$command_log"
first_line="$(grep -n 'Subject: first' "$command_log" | head -n1 | cut -d: -f1)"
second_line="$(grep -n 'Subject: second' "$command_log" | head -n1 | cut -d: -f1)"
[[ "$first_line" -lt "$second_line" ]]

message retained@example.com retained | run_epel submit >/dev/null
message later@example.com later | run_epel submit >/dev/null
if EPEL_TEST_FAIL_SEND=1 run_epel send >/dev/null 2>&1; then
  printf 'expected failed send to stop queue processing\n' >&2
  exit 1
fi
[[ "$(find "$test_home/.local/share/epel/queue" -type f -name '*.eml' | wc -l)" -eq 2 ]]
run_epel send >/dev/null

run_epel send-immediate
message immediate@example.com immediate | run_epel submit
grep -q 'msmtp --account=immediate@example.com -t --read-envelope-from' "$command_log"

if printf 'To: receiver@example.net\n\nmissing sender\n' | run_epel submit >/dev/null 2>&1; then
  printf 'expected submit without From to fail\n' >&2
  exit 1
fi

mkdir -p "$test_home/Mail/account/cur"
printf 'original mail\n' >"$test_home/Mail/account/cur/message"
run_epel backup >/dev/null
first_snapshot="$(find "$test_home/backup/mail" -mindepth 1 -maxdepth 1 -type d -name '20*' | sort | head -n1)"
[[ "$(cat "$first_snapshot/Mail/account/cur/message")" == 'original mail' ]]
printf 'changed mail\n' >"$test_home/Mail/account/cur/message"
run_epel backup >/dev/null
[[ "$(cat "$first_snapshot/Mail/account/cur/message")" == 'original mail' ]]
[[ "$(cat "$test_home/backup/mail/latest/Mail/account/cur/message")" == 'changed mail' ]]

snapshot_count="$(find "$test_home/backup/mail" -mindepth 1 -maxdepth 1 -type d -name '20*' | wc -l)"
if EPEL_TEST_FAIL_SYNC=1 run_epel sync-backup >/dev/null 2>&1; then
  printf 'expected sync-backup to fail when synchronization fails\n' >&2
  exit 1
fi
[[ "$(find "$test_home/backup/mail" -mindepth 1 -maxdepth 1 -type d -name '20*' | wc -l)" -eq "$snapshot_count" ]]

run_epel sync-enable
run_epel sync-disable
run_epel backup-enable
run_epel backup-disable
grep -q 'systemctl --user enable --now epel-sync.timer' "$command_log"
grep -q 'systemctl --user enable epel-backup.service' "$command_log"

feature_home="$tmpdir/feature-home"
mkdir -p "$feature_home"
env \
  HOME="$feature_home" \
  PATH="$fake_bin:/usr/bin:/bin" \
  EPEL_TEST_COMMAND_LOG="$command_log" \
  DOCPUNCT_FEATURE_DIR="$repo_root/features/epel" \
  "$repo_root/features/epel/install.sh"
[[ -L "$feature_home/.local/bin/epel" ]]
[[ -L "$feature_home/.local/lib/epel/bin/msmtp" ]]
[[ -L "$feature_home/.config/systemd/user/epel-sync.timer" ]]

old_feature_dir="$tmpdir/old-checkout/features/epel"
ln -sfn -- "$old_feature_dir/epel" "$feature_home/.local/bin/epel"
ln -sfn -- "$old_feature_dir/msmtp-wrapper" "$feature_home/.local/lib/epel/bin/msmtp"
for unit in epel-sync.service epel-sync.timer epel-backup.service; do
  ln -sfn -- "$old_feature_dir/$unit" "$feature_home/.config/systemd/user/$unit"
done
env \
  HOME="$feature_home" \
  PATH="$fake_bin:/usr/bin:/bin" \
  EPEL_TEST_COMMAND_LOG="$command_log" \
  DOCPUNCT_FEATURE_DIR="$repo_root/features/epel" \
  "$repo_root/features/epel/relink.sh"
[[ "$(readlink "$feature_home/.local/bin/epel")" == "$repo_root/features/epel/epel" ]]
[[ "$(readlink "$feature_home/.local/lib/epel/bin/msmtp")" == "$repo_root/features/epel/msmtp-wrapper" ]]
[[ "$(readlink "$feature_home/.config/systemd/user/epel-sync.timer")" == "$repo_root/features/epel/epel-sync.timer" ]]

mkdir -p "$feature_home/.local/share/epel/queue"
printf 'preserve me\n' >"$feature_home/.local/share/epel/queue/unsent.eml"
env \
  HOME="$feature_home" \
  PATH="$fake_bin:/usr/bin:/bin" \
  EPEL_TEST_COMMAND_LOG="$command_log" \
  DOCPUNCT_FEATURE_DIR="$repo_root/features/epel" \
  "$repo_root/features/epel/remove.sh" >/dev/null
[[ ! -e "$feature_home/.local/bin/epel" ]]
[[ ! -e "$feature_home/.config/systemd/user/epel-sync.timer" ]]
[[ -f "$feature_home/.local/share/epel/queue/unsent.eml" ]]

printf '%s\n' 'epel smoke tests passed'
