# epel — Personal Mail Architecture

## Status

Approved architecture.

The v1 implementation is provided by two docpunct features:

* `debian-mail-packages` installs `isync`, `notmuch`, `libnotmuch-dev`,
  `msmtp`, `rsync`, `libsecret-tools`, `util-linux`, and `w3m` and leaves them
  installed during removal. `libnotmuch-dev` supplies the unversioned
  `libnotmuch.so` loader name required by notmuch.nvim.
* `epel` depends on `debian-mail-packages`, `neovim`, and `dotfiles`; it owns
  the command, private notmuch.nvim send wrapper, and systemd user units.

Detailed instructions live in `features/epel/HOWTO.md`, separate from
docpunct's root HOWTO.

Goals:

* KISS
* Long-term maintainability
* Maildir as canonical local storage
* Fast local search
* Neovim-first workflow
* GUI clients available when desired
* Local ownership of email data
* Recovery possible even if Gmail account is lost
* Minimal vendor lock-in
* Portable across Linux systems
* Multiple email accounts supported without changing the architecture
* All mail operations exposed through one simple CLI entrypoint

---

# Architecture Overview

```text
                         Gmail / IMAP Provider
                                  ↕
                               mbsync
                                  ↕
                         ~/Mail/<email_address>
                                  ↓
                               notmuch
                                  ↓
                        Neovim + notmuch.nvim
                                  ↓
                                msmtp
                                  ↓
                         Gmail / SMTP Provider


                                ~/Mail/
                                  ↓
                       rsync snapshot backups
                                  ↓
                 ~/backup/mail/YYYY-MM-DD/Mail/
                    (whole-mail-tree snapshots)


Thunderbird / Evolution
            ↕
    Gmail / IMAP Provider + SMTP
```

---

# Core Principles

## Canonical Local Storage

Canonical storage format:

```text
Maildir
```

Top-level local mail root:

```text
~/Mail
```

Per-account Maildir roots:

```text
~/Mail/<email_address>
```

Examples:

```text
~/Mail/chris@example.com
~/Mail/work@example.org
~/Mail/personal@gmail.com
```

Each email address gets its own Maildir root. This keeps future accounts independent while preserving the same architecture for every account.

All mail is stored locally as Maildir files.

The entire `~/Mail` tree is considered the long-term asset.

Everything else may be replaced in the future.

---

## Multiple Account Layout

The account identifier should be the email address itself.

Example:

```text
~/Mail/
├── chris@example.com/
├── work@example.org/
└── personal@gmail.com/
```

Rules:

* One Maildir root per email address
* Do not use provider-specific names such as `gmail-work`
* Do not encode account purpose into the storage path
* Account purpose can be documented in config files or comments instead
* Adding a new account should only require adding a new directory under `~/Mail`

This makes the layout stable even if an account changes provider, purpose, or role.

---

## Synchronization

Tool:

```text
mbsync (from isync)
```

Responsibilities:

* Download mail from Gmail or another IMAP provider
* Upload mail changes to the provider
* Synchronize IMAP folders
* Maintain Maildir structure under `~/Mail/<email_address>`

Does not:

* Index mail
* Search mail
* Send mail
* Provide UI

---

## Search and Indexing

Tool:

```text
notmuch
```

Responsibilities:

* Search
* Threading
* Tagging
* Fast local indexing

Recommended database scope:

```text
~/Mail
```

This allows notmuch to search across all local accounts.

Recommended workflow tags:

```text
todo
waiting
review
gps
reference
```

Tag meanings:

* `todo` — mail that requires an action from me
* `waiting` — mail where I am waiting for somebody else to respond or act
* `review` — mail that needs deeper reading or evaluation before deciding the next action
* `gps` — mail containing or related to bike GPS traces, GPX files, routes, or ride exports
* `reference` — mail kept for future lookup, documentation, receipts, manuals, reservations, or other durable information

Tags are stored in the notmuch database.

Tags should describe workflow or long-term retrieval value, not replace the per-account Maildir layout.

---

## Primary Mail User Interface

Tool:

```text
Neovim + notmuch.nvim
```

Responsibilities:

* Search mail
* Read mail
* Organize mail
* Compose mail

Neovim is the primary daily interface.

---

## Sending Mail

Tool:

```text
msmtp
```

Flow:

```text
Neovim
  ↓
msmtp
  ↓
Gmail / SMTP Provider
```

Responsibilities:

* SMTP delivery only
* Select the correct SMTP account based on sender address

---

# Unified Command Interface

All mail operations should be grouped under one command:

```bash
epel
```

`epel` is an abbreviation for **epistula electronica**, Latin for electronic letter/mail.

The goal is to have one stable command-line interface that can later be called by a simple Ubuntu desktop GUI.

```text
epel CLI
   ↑
GUI buttons
   ↓
mbsync / notmuch / msmtp / rsync
```

The GUI should not implement mail logic itself. It should call `epel` commands.

---

## Command Set

### Help and Configuration

```bash
epel help
epel config
```

Meanings:

* `epel help` — show all supported commands, their purpose, current assumptions, and examples
* `epel config` — assist the user in adding or reviewing mail account configuration

`epel config` should initially focus on:

* Gmail
* French Orange mail provider

When possible, it should generalize to any IMAP/SMTP provider by asking for:

* email address
* IMAP hostname
* IMAP port
* IMAP security mode
* SMTP hostname
* SMTP port
* SMTP security mode
* username
* authentication method
* local Maildir path

The first implementation of `epel config` does not need to edit config files automatically.

A simple and safe first version may print clear instructions explaining which files to modify and what to add.

Likely config files:

```text
~/.mbsyncrc
~/.msmtprc
~/.notmuch-config
```

It may also suggest or create account-specific directories under:

```text
~/Mail/<email_address>
```

Future versions may become interactive and write configuration files after confirmation.

---

### Sync Commands

```bash
epel sync
epel sync-enable
epel sync-disable
epel sync-status
```

Meanings:

* `epel sync` — manually receive mail with `mbsync` and index it with `notmuch new`
* `epel sync-enable` — enable automatic sync every 15 minutes
* `epel sync-disable` — disable automatic sync
* `epel sync-status` — show whether automatic sync is enabled and when sync last ran

Recommended implementation for `epel sync`:

```text
mbsync --all
notmuch new
```

Automatic sync should run every 15 minutes when enabled.

Automatic sync is implemented using a `systemd --user` timer on Ubuntu.

Cron support is a future portability extension.

---

### Send Commands

```bash
epel send
epel submit
epel send-immediate
epel send-queued
epel send-status
```

Meanings:

* `epel send` — flush queued outgoing mail now
* `epel submit` — read one RFC 5322 message from standard input and send it or
  enqueue it according to the active mode
* `epel send-immediate` — set send mode to immediate delivery
* `epel send-queued` — set send mode to queued delivery
* `epel send-status` — show active send mode and queued mail count

Two send modes are supported:

```text
immediate
queued
```

In immediate mode, composed mail is sent directly through `msmtp`.

In queued mode, composed mail is written to a local outgoing queue first and later sent by `epel send`.

Queued mode is useful when offline, on unstable networks, or when outgoing mail should be reviewed before delivery.

---

### Backup Commands

```bash
epel backup
epel backup-enable
epel backup-disable
epel backup-status
epel sync-backup
```

Meanings:

* `epel backup` — manually create an rsync snapshot of `~/Mail`
* `epel backup-enable` — enable automatic backup after Ubuntu desktop login
* `epel backup-disable` — disable automatic login backup
* `epel backup-status` — show whether automatic backup is enabled and when backup last ran
* `epel sync-backup` — run `epel sync` and then `epel backup`

Automatic backup runs once when the systemd user manager starts after login.

Backup should include only:

```text
~/Mail
```

Backup should not include:

* notmuch database
* notmuch configuration
* mbsync configuration
* msmtp configuration
* Neovim configuration
* GUI client configuration

Those configuration files should be managed separately, for example through dotfiles.

---

# Receive, Send, and Backup Operation

## Operating Principle

Mail operations should be controllable from the command line first.

A future Ubuntu desktop GUI should call `epel` instead of implementing separate logic.

This keeps the architecture simple:

```text
epel commands
   ↑
GUI buttons
   ↓
mbsync / notmuch / msmtp / rsync
```

The GUI is only a convenience layer. The `epel` script is the source of truth.

---

## Receive and Index Mail

Receiving mail is handled by `mbsync`; indexing is handled by `notmuch`.

Recommended wrapper command:

```bash
epel sync
```

Responsibilities:

```text
mbsync --all
notmuch new
```

Meaning:

* `mbsync` synchronizes all configured accounts under `~/Mail/<email_address>`
* `notmuch new` indexes newly arrived Maildir messages
* notmuch tags and searches only after mail exists locally

notmuch itself does not receive mail. It may run hooks, but the preferred architecture is an explicit wrapper script because it is easier to debug, easier to trigger manually, and easier to expose through a future GUI button.

Manual trigger:

```bash
epel sync
```

Automated trigger:

```text
every 15 minutes, when enabled
```

The 15-minute automatic sync should be enabled or disabled by `epel` and later by GUI.

---

## Sending Mail and Account Selection

Sending mail is handled by `msmtp`.

The correct sending account should be determined from the message's `From:` address.

Recommended rule:

```text
From address → msmtp account → SMTP provider
```

Example:

```text
From: chris@gmail.com
        ↓
msmtp account chris@gmail.com
        ↓
smtp.gmail.com
```

```text
From: chris@orange.fr
        ↓
msmtp account chris@orange.fr
        ↓
Orange SMTP server
```

This means the composer should make the sender address explicit before sending.

Recommended behavior:

* Replies should normally use the same account that received the original message
* New messages should use a configured default account unless the user chooses another sender
* `msmtp` should route by envelope sender / `From:` address
* If the `From:` address does not match a configured account, sending should fail clearly rather than guessing

Recommended implementation direction:

* Configure one `msmtp` account per email address
* Make account names equal to email addresses where practical
* Use `msmtp` account selection based on sender address
* Configure Neovim/notmuch.nvim or the mail composition layer to set the desired `From:` header

notmuch.nvim uses notmuch's configured primary address for new messages and
`notmuch reply` for replies. The user must review the explicit `From:` header;
epel refuses a missing or invalid sender rather than guessing an account.

The architecture preference is clear: account selection should be based on the explicit sender address, not on folder location, not on provider name, and not on hidden state.

---

## Send Modes

Two send modes are supported:

```text
immediate
queued
```

### Immediate Send Mode

In immediate mode, composed mail is sent directly through `msmtp`.

Flow:

```text
Neovim / notmuch.nvim
        ↓
      msmtp
        ↓
 SMTP provider
```

Use this mode when online and when immediate delivery is desired.

Enable with:

```bash
epel send-immediate
```

### Queued Send Mode

In queued mode, composed mail is written to a local outgoing queue first.

Flow:

```text
Neovim / notmuch.nvim
        ↓
 local outgoing queue
        ↓
    epel send
        ↓
      msmtp
        ↓
 SMTP provider
```

Use this mode when offline, on unstable networks, or when reviewing outgoing mail before delivery.

Enable with:

```bash
epel send-queued
```

Flush queue with:

```bash
epel send
```

Status:

```bash
epel send-status
```

---

## Backup Execution

Backups are handled by `rsync` snapshot scripts.

Recommended wrapper command:

```bash
epel backup
```

Responsibilities:

```text
create immutable rsync snapshot of ~/Mail
update ~/backup/mail/latest
```

Manual trigger:

```bash
epel backup
```

Automated trigger:

```text
once when the systemd user manager starts after login, when enabled
```

The automatic backup should run after login, not necessarily before the desktop is usable.

---

## Relationship Between Sync and Backup

Sync and backup are separate operations.

```text
epel sync   = receive/index mail
epel backup = snapshot ~/Mail
```

They can be run independently.

Combined command:

```bash
epel sync-backup
```

Flow:

```text
epel sync
   ↓
epel backup
```

This is useful when the user wants to explicitly pull the latest mail and then immediately protect the local mail tree.

The backup should not depend on a successful sync in general, because a backup of the current local state is still valuable even when the network is unavailable.

For `epel sync-backup`, a sync failure stops the operation. No backup is made,
and epel tells the user to run `epel backup` separately if the current local
tree should still be protected.

---

# Future Ubuntu Desktop GUI

The future GUI should remain minimal and call `epel` commands.

Recommended buttons and controls:

```text
Sync Mail              → epel sync
Flush Queue            → epel send
Backup Mail            → epel backup
Sync + Backup          → epel sync-backup

Automatic sync         → epel sync-enable / epel sync-disable
Automatic backup       → epel backup-enable / epel backup-disable
Send mode              → epel send-immediate / epel send-queued
Configuration help     → epel config
Help                   → epel help
```

The GUI should display basic status only:

```text
last sync time
last backup time
automatic sync state
automatic backup state
current send mode
queued mail count
last error, if any
```

It should not become a mail client. Reading, searching, tagging, and composing remain the responsibility of Neovim, notmuch.nvim, Thunderbird, or Evolution.

---

# Backup Strategy

## Objective

Recoverability guarantee:

> Mail that reached the local Maildir and a completed snapshot remains
> recoverable even if it is later deleted from the provider.

Mail deleted remotely before it was synchronized locally cannot be protected
by this design.

---

## Backup Method

Use rsync snapshot backups of the entire `~/Mail` tree.

Backup root:

```text
~/backup/mail
```

Example live mail layout:

```text
~/Mail/
├── chris@example.com/
├── work@example.org/
└── personal@gmail.com/
```

Example backup layout:

```text
~/backup/mail/
├── 2026-06-15T080000.000000000/
│   └── Mail/
│       ├── chris@example.com/
│       ├── work@example.org/
│       └── personal@gmail.com/
│
├── 2026-06-16T080000.000000000/
│   └── Mail/
│       ├── chris@example.com/
│       ├── work@example.org/
│       └── personal@gmail.com/
│
├── 2026-06-17T080000.000000000/
│   └── Mail/
│       ├── chris@example.com/
│       ├── work@example.org/
│       └── personal@gmail.com/
│
└── latest -> 2026-06-17T080000.000000000
```

The backup is account-aware because account directories are preserved inside the snapshot, but the backup job operates on the whole `~/Mail` tree.

This is preferred over per-account backup roots because:

* One backup job covers every account
* New accounts are automatically included
* A snapshot represents the full mail state at a point in time
* Recovery is simpler
* The backup layout remains stable as accounts are added or removed

Snapshots are created with:

```bash
SNAPSHOT_DATE="$(date -u +%Y-%m-%dT%H%M%S.%N)"
BACKUP_ROOT="$HOME/backup/mail"
SNAPSHOT_DIR="$BACKUP_ROOT/$SNAPSHOT_DATE"

mkdir -p "$SNAPSHOT_DIR"

rsync -a --checksum \
  --link-dest="$BACKUP_ROOT/latest/Mail" \
  "$HOME/Mail/" \
  "$SNAPSHOT_DIR/Mail/"

ln -sfn "$SNAPSHOT_DIR" "$BACKUP_ROOT/latest"
```

Notes:

* The trailing slash on `$HOME/Mail/` is intentional
* The snapshot stores the mail tree as `Mail/` inside each timestamped snapshot
* `latest` points to the most recent timestamped snapshot
* `--link-dest` points to the previous snapshot's `Mail` directory

---

## Snapshot Policy

Requirements:

* Historical snapshots are immutable
* Old snapshots are never modified
* Old snapshots are never automatically deleted
* No deletion propagation into existing snapshots
* Deleted provider-side mail remains recoverable from older local snapshots

Avoid:

```bash
rsync --delete
```

against snapshot directories.

`--delete` may be useful only when maintaining a separate mutable mirror. It should not be used for immutable historical snapshots.

---

## Recovery

To inspect a historical snapshot:

```bash
cd ~/backup/mail/2026-06-15T080000.000000000/Mail
```

To inspect one account:

```bash
cd ~/backup/mail/2026-06-15T080000.000000000/Mail/chris@example.com
```

Examples:

```bash
grep -Ri "invoice" .
```

```bash
less path/to/mail
```

To restore the full mail tree from the latest snapshot:

```bash
rsync -a ~/backup/mail/latest/Mail/ ~/Mail/
```

To restore one account:

```bash
rsync -a \
  ~/backup/mail/latest/Mail/chris@example.com/ \
  ~/Mail/chris@example.com/
```

A snapshot can also be copied elsewhere and indexed again with notmuch.

---

# GUI Clients

## Purpose

Provide occasional GUI access.

Supported clients:

* Thunderbird
* Evolution

---

## Configuration

GUI clients connect directly to Gmail or the relevant IMAP provider.

```text
Thunderbird
    ↕
 Gmail / IMAP Provider

Thunderbird
    ↕
 Gmail / SMTP Provider
```

Same for Evolution.

---

## Important Rule

Do NOT point GUI clients at:

```text
~/Mail/<email_address>
```

Do NOT share the Maildir directly.

Reason:

* Simpler architecture
* Fewer synchronization issues
* No Maildir locking concerns
* No client interaction problems

---

## Retention

GUI clients only need recent mail.

Suggested range:

```text
6–12 months
```

Historical mail remains available through:

```text
Maildir
+
notmuch
+
backup snapshots
```

---

# Version 1 Implementation Decisions

* Account configuration is instructional; epel does not write mbsync, msmtp,
  notmuch, or credential configuration.
* Credentials are retrieved with `secret-tool` from the desktop keyring.
  Stronger keyring and OAuth integration remain future security work.
* Automation uses systemd user units. Cron is a future extension.
* State is stored under `~/.local/state/epel`; queued messages are stored under
  `~/.local/share/epel/queue` with private permissions.
* Mail and backup roots default to `~/Mail` and `~/backup/mail` and can be
  overridden through `~/.config/epel/config`.
* Sync, send, and backup operations use non-blocking `flock` locks.
* Manual output goes to the terminal and scheduled output goes to the systemd
  journal. The most recent operation error is also recorded in epel state.
* `epel sync-backup` stops after a failed sync, makes no backup, and tells the
  user to run `epel backup` separately if desired.
* The queue is FIFO. A successful item is removed; processing stops on the
  first failure and preserves it and all later items.
* Sent-message retention relies on the provider Sent folder being synchronized
  back through mbsync in v1.
* notmuch.nvim sync runs `epel sync`. Because the plugin currently hardcodes
  `msmtp`, Neovim prepends a private epel wrapper directory to its PATH; the
  wrapper forwards messages to `epel submit`.
* Thunderbird and Evolution remain optional documented clients and are not
  installed by epel.

---

# Future Enhancements

Optional.

## Backup Encryption

Possible solutions:

* LUKS
* gocryptfs
* VeraCrypt

No architectural changes required.

---

## NAS Replication

```text
Local snapshots
      ↓
      NAS
```

using rsync.

---

## Cloud Replication

```text
Local snapshots
      ↓
Cloud storage
```

Possible tools:

* rsync
* rclone

---

# Non-Goals

Not part of this architecture:

* Local IMAP server
* Dovecot
* Shared Maildir access by GUI clients
* Custom archive Maildir
* Gmail API specific tooling
* Proprietary mail databases
* Full graphical mail client inside the future GUI

---

# Design Philosophy

The architecture is intentionally layered.

```text
Mail Provider
  ↕
mbsync
  ↕
Maildir under ~/Mail/<email_address>
  ↓
notmuch
  ↓
Neovim
```

Each layer has one responsibility.

The most important design decision is:

```text
Maildir under ~/Mail is the canonical storage format.
```

The most important operational decision is:

```text
epel is the single command interface for sync, send, backup, help, and configuration assistance.
```

If any individual tool becomes obsolete:

* epel
* notmuch
* notmuch.nvim
* Neovim
* Thunderbird
* Evolution
* msmtp
* mbsync

then the Maildir archive remains usable and recoverable.
