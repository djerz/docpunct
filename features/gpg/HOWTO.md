# GPG feature HOWTO

The `gpg` feature installs the command-line tools required for encrypted,
`pass`-compatible credential storage. It does not create, select, export, or
delete keys. Those identity and recovery decisions remain user-owned.

## Inspect or create a key

List existing secret keys and their fingerprints:

```sh
gpg --list-secret-keys --keyid-format=long --with-subkey-fingerprint
```

Reuse an existing personal key when it has an encryption-capable key or
subkey. Otherwise create one interactively:

```sh
gpg --full-generate-key
```

Choose the identity, expiration, and a strong passphrase deliberately. Record
the complete primary-key fingerprint, not a short key ID.

## Publish the public key (optional)

Publishing a key allows other people and services to retrieve the public key
and verify signatures. Upload it to the configured keyserver with the complete
fingerprint:

```sh
gpg --send-keys FULL_GPG_FINGERPRINT
```

Keyserver publication exposes the key's user IDs, including email addresses,
and may not be practically reversible. Alternatively, export an ASCII-armored
public key and upload it only to the services that need it:

```sh
gpg --armor --export you@example.com >public.asc
```

Public keys can be added to:

- [GitHub GPG keys settings](https://github.com/settings/keys)
- [GitLab GPG keys settings](https://gitlab.com/-/user_settings/gpg_keys)

The exported `public.asc` contains only public key material. Never export or
upload the private key.

## Use the key with Git

List secret keys and find the complete signing-key fingerprint:

```sh
gpg --list-secret-keys --keyid-format=long
```

Configure Git to sign commits with that key:

```sh
git config --global user.signingkey FULL_GPG_FINGERPRINT
git config --global commit.gpgsign true
git config --global gpg.program gpg
```

Test signing in a repository that has a staged test change:

```sh
git commit -S -m "Signed commit"
git log --show-signature -1
```

The first command creates a real commit. Use a disposable repository if the
commit should not become part of an existing project.

## Initialize pass

Initialize the password store with that fingerprint:

```sh
pass init FULL_GPG_FINGERPRINT
```

This writes `~/.password-store/.gpg-id`. Credential files stored below that
directory are encrypted to the selected key.

Verify readiness without displaying any credential. When running the check
directly from the repository, provide the feature environment used by
docpunct:

```sh
DOCPUNCT_FEATURE_DIR="$PWD/features/gpg" features/gpg/check-readiness.sh
```

## Terminal and SSH sessions

GCM uses `SSH_TTY` automatically in SSH sessions. The docpunct `dotfiles`
feature also adds this guarded setup through the managed shared shell
environment:

```sh
if tty_path="$(tty 2>/dev/null)"; then
    export GPG_TTY="$tty_path"
fi
```

After updating dotfiles, open a new shell or source the managed environment:

```sh
. "$HOME/.config/docpunct/session-env.sh"
```

If the agent attempts to use a graphical prompt on a command-line-only host,
add this line to `~/.gnupg/gpg-agent.conf`:

```text
pinentry-program /usr/bin/pinentry-curses
```

Then restart the agent:

```sh
gpgconf --kill gpg-agent
```

Do not force terminal pinentry on a desktop unless that is the desired
machine-wide behavior for the user account.

## Backup and recovery

Back up the private key and its revocation certificate to protected offline
storage. A copy of `~/.password-store` is not sufficient: its contents cannot
be recovered without the corresponding private key and passphrase.

Test key restoration and decryption before relying on the store. Never commit
private keys, revocation material, password-store contents, tokens, or
passphrases to docpunct.

After the key exists and `pass` is initialized, install GCM with:

```sh
./bin/docpunct install gcm-gpg
```
