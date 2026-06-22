# epel HOWTO

`epel` is docpunct's command-line interface for a local Maildir workflow. It
synchronizes mail with mbsync, indexes it with notmuch, sends it through msmtp,
and creates immutable timestamped snapshots with rsync.

The canonical mail data is stored under `~/Mail`. Account configuration and
credentials remain user-owned and are never written by docpunct.

## Installation

```sh
./bin/docpunct install epel
```

This installs the separate `debian-mail-packages` dependency, Neovim and
managed dotfiles when needed, the `epel` command, and systemd user unit files.
Automatic synchronization and backup remain disabled until explicitly enabled.
The package dependency includes `libnotmuch-dev`, which supplies the
unversioned `libnotmuch.so` name loaded by notmuch.nvim.

Run:

```sh
epel help
epel config
```

## Paths

```text
~/Mail                              canonical Maildir tree
~/backup/mail                       immutable mail snapshots
~/.config/epel/config               optional epel runtime configuration
~/.local/state/epel                 status, mode, error, and lock files
~/.local/share/epel/queue           queued outgoing messages
~/.config/systemd/user              epel systemd user-unit links
```

Override the mail and backup roots in `~/.config/epel/config`:

```sh
EPEL_MAIL_ROOT="$HOME/Mail"
EPEL_BACKUP_ROOT="$HOME/backup/mail"
```

This file is sourced as shell code. It must remain owned and writable only by
the user.

## Credentials and desktop keyring

The initial implementation uses `secret-tool`, supplied by
`libsecret-tools`, to retrieve credentials from the desktop keyring. Store a
separate IMAP and SMTP secret for each address:

```sh
secret-tool store --label='epel IMAP personal@example.com' \
  service epel-imap account personal@example.com

secret-tool store --label='epel SMTP personal@example.com' \
  service epel-smtp account personal@example.com
```

The commands prompt for the secret. Gmail normally requires OAuth or an app
password rather than the main account password. Provider policies can change;
verify the provider's current authentication requirements before configuring
an account.

Desktop-keyring command execution is an initial credential design, not the
final security model. More explicit keyring integration, OAuth token handling,
and stronger isolation are future improvement points.

Ubuntu releases that confine mbsync with AppArmor may block `PassCmd` by
default. `debian-mail-packages` adds a marked local mbsync rule that confines
the command shell to a helper profile and permits only `secret-tool` to leave
that helper profile. The rule is stored in `/etc/apparmor.d/local/mbsync` and
is retained by the feature's conservative removal policy.

## mbsync configuration

Create `~/.mbsyncrc` with mode `0600`. One account uses one Maildir root whose
name is the complete email address. This abbreviated Gmail example shows the
required structure:

```text
IMAPAccount personal@example.com
Host imap.gmail.com
User personal@example.com
PassCmd "secret-tool lookup service epel-imap account personal@example.com"
TLSType IMAPS

IMAPStore personal@example.com-remote
Account personal@example.com

MaildirStore personal@example.com-local
SubFolders Verbatim
Path ~/Mail/personal@example.com/
Inbox ~/Mail/personal@example.com/INBOX

Channel personal@example.com
Far :personal@example.com-remote:
Near :personal@example.com-local:
Patterns *
Create Both
SyncState *
```

Orange accounts follow the same structure. At the time this architecture was
written, the expected endpoints are `imap.orange.fr` with IMAPS on port 993
and `smtp.orange.fr` with TLS-authenticated SMTP. Verify Orange's current
ports, security mode, and authentication requirements in its official support
documentation before use.

Test synchronization directly before enabling automation:

```sh
mbsync --all
```

## notmuch configuration

Run `notmuch setup`, or create `~/.notmuch-config`. Its database path should
cover the complete mail tree:

```ini
[database]
path=/home/USER/Mail

[user]
name=Your Name
primary_email=personal@example.com
other_email=work@example.org

[new]
tags=unread;inbox;
ignore=.mbsyncstate;.uidvalidity
```

Replace `/home/USER` with the actual home directory; notmuch configuration
does not expand every shell expression consistently. Workflow tags such as
`todo`, `waiting`, `review`, `gps`, and `reference` can then be managed from
notmuch or Neovim.

The ignore list names mbsync's per-mailbox synchronization state and Maildir
UID-validity metadata. Without it, `notmuch new` safely rejects those files as
non-mail but prints an `Ignoring non-mail file` note for every synchronized
folder. The entries match only those exact basenames anywhere below the mail
root; they do not exclude messages.

Test indexing:

```sh
notmuch new
notmuch search tag:inbox
```

## msmtp configuration

Create `~/.msmtprc` with mode `0600`. Account names must equal their complete
sender addresses because `epel submit` selects an account from the message's
`From:` header:

```text
defaults
auth on
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt

account personal@example.com
host smtp.gmail.com
port 587
tls_starttls on
from personal@example.com
user personal@example.com
passwordeval secret-tool lookup service epel-smtp account personal@example.com

account default : personal@example.com
```

Add another account block for each address. Verify provider endpoints and
authentication policy rather than copying Gmail settings to another provider.

## Synchronization

```sh
epel sync
epel sync-enable
epel sync-disable
epel sync-status
```

`epel sync` holds a non-blocking mail lock, runs `mbsync --all`, and only then
runs `notmuch new`. Backup uses the same lock, so synchronization and snapshots
cannot overlap when invoked through epel. The timer runs five minutes after the
user manager starts and then every fifteen minutes.

## Sending and queueing

```sh
epel send-immediate
epel send-queued
epel send-status
epel send
```

`epel submit` reads one RFC 5322 message from standard input. In immediate
mode it sends through `/usr/bin/msmtp`. In queued mode it stores the message
with mode `0600`. `epel send` processes queued messages FIFO, removes each
successfully sent item, and stops on the first failure.

notmuch.nvim currently hardcodes an `msmtp` invocation. Its Lazy configuration
puts `~/.local/lib/epel/bin` first on Neovim's process PATH. The private wrapper
at that location forwards the message to `epel submit`; other applications
continue to use the system msmtp binary.

Sent messages rely on the provider's Sent folder being synchronized back by
mbsync. Epel v1 does not create a separate local sent copy. Confirm this
behavior for every configured provider.

With the currently pinned notmuch.nvim version, sending does not automatically
close the draft or its temporary send terminal. After confirming a send with
`Ctrl-g Ctrl-g`, wait for the success notification. In the send terminal,
press `Ctrl-\` followed by `Ctrl-n`, then run `:q`. Back in the sent draft,
run `:bdelete` to delete that temporary buffer and return to the previous mail
or thread buffer.

## Backups

```sh
epel backup
epel backup-enable
epel backup-disable
epel backup-status
epel sync-backup
```

Snapshots use UTC timestamps such as:

```text
~/backup/mail/2026-06-21T143000.123456789/Mail/
```

Unchanged files are identified with checksums and hard-linked from the previous
snapshot through rsync's `--link-dest`. `latest` points at the newest completed
snapshot. Epel never updates or automatically deletes a completed snapshot.

`epel sync-backup` does not create a backup when synchronization fails. It
reports this explicitly; run `epel backup` separately when the current local
tree should still be protected.

The recoverability guarantee applies only after a message has reached the
local Maildir and a completed snapshot. Mail deleted remotely before it was
downloaded cannot be recovered by this design. A backup on the same physical
disk also does not protect against disk loss.

## systemd user services

Installed unit links:

```text
~/.config/systemd/user/epel-sync.service
~/.config/systemd/user/epel-sync.timer
~/.config/systemd/user/epel-backup.service
```

Useful commands:

```sh
systemctl --user daemon-reload
systemctl --user list-timers epel-sync.timer
systemctl --user status epel-sync.timer epel-sync.service
systemctl --user start epel-sync.service
systemctl --user stop epel-sync.timer
systemctl --user enable --now epel-sync.timer
systemctl --user disable --now epel-sync.timer

systemctl --user status epel-backup.service
systemctl --user start epel-backup.service
systemctl --user enable epel-backup.service
systemctl --user disable --now epel-backup.service
```

`epel-backup.service` is enabled under `default.target`, so it runs when the
systemd user manager starts. It is not intended to run once for every
simultaneous graphical session.

Inspect logs with:

```sh
journalctl --user -u epel-sync.service
journalctl --user -u epel-sync.service --since today
journalctl --user -u epel-backup.service
journalctl --user -f -u epel-sync.service
```

After changing a unit, run `systemctl --user daemon-reload`. Change the timer
interval with a systemd drop-in rather than editing docpunct's managed unit:

```sh
systemctl --user edit epel-sync.timer
```

For example:

```ini
[Timer]
OnUnitActiveSec=
OnUnitActiveSec=30m
```

Then reload and restart the timer. Cron support is a possible future extension
for systems without a systemd user manager.

## Errors and exit status

Manual commands write normal output to the terminal. Scheduled output is
captured by the systemd journal. `~/.local/state/epel/last-error` records the
last failed operation; a later successful operation clears it.

Exit status meanings:

```text
0   success
1   operation or configuration failure
2   command-line usage error
75  another instance of that operation already holds the lock
```

## Removal

```sh
./bin/docpunct remove epel
```

Removal disables automation and removes only docpunct-owned commands and unit
links. It preserves account configuration, credentials, state, queued mail,
`~/Mail`, snapshots, and installed mail packages.

Thunderbird and Evolution are optional remote IMAP/SMTP clients. They must not
open epel's Maildir directly. Packaging them through docpunct is future work.
