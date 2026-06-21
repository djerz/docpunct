#!/usr/bin/env bash
set -euo pipefail

apt-get update
apt-get install -y --no-install-recommends \
  bash \
  ca-certificates \
  shellcheck \
  sudo
rm -rf /var/lib/apt/lists/*

useradd --create-home --shell /bin/bash docpunct-test
printf 'docpunct-test ALL=(ALL) NOPASSWD:ALL\n' >/etc/sudoers.d/docpunct-test
chmod 0440 /etc/sudoers.d/docpunct-test

sudo -u docpunct-test \
  HOME=/home/docpunct-test \
  DOCPUNCT_CACHE_DIR=/home/docpunct-test/.cache/docpunct \
  bash -lc '
    set -euo pipefail
    cd /workspace/docpunct
    bash -n bin/docpunct features/*/*.sh features/epel/epel features/epel/msmtp-wrapper
    shellcheck bin/docpunct features/*/*.sh features/epel/epel features/epel/msmtp-wrapper
    ./tests/smoke.sh
    ./bin/docpunct install debian-cli-packages
    dpkg-query -W -f="\${Status}\n" libicu-dev | grep -qx "install ok installed"
    test -x /usr/bin/fdfind
    test -L "$HOME/.local/bin/fd"
    test "$(readlink "$HOME/.local/bin/fd")" = "/usr/bin/fdfind"
    ./bin/docpunct update debian-cli-packages
    ./bin/docpunct install gpg
    for package in gnupg pass pinentry-curses; do
      dpkg-query -W -f="\${Status}\n" "$package" | grep -qx "install ok installed"
    done
    gpg --batch --passphrase "" --quick-generate-key \
      "docpunct container test <docpunct@example.invalid>" default default never
    gpg_fingerprint="$(gpg --batch --with-colons --list-secret-keys \
      "docpunct@example.invalid" | awk -F: '\''$1 == "fpr" { print $10; exit }'\'')"
    pass init "$gpg_fingerprint"
    ./bin/docpunct install gcm-gpg
    git config --global --get-all include.path | grep -Fx \
      "$HOME/.config/docpunct/git-credential-manager.gitconfig"
    grep -F "credentialStore = gpg" \
      "$HOME/.config/docpunct/git-credential-manager.gitconfig"
    ./bin/docpunct install debian-mail-packages
    for package in isync notmuch msmtp rsync libsecret-tools util-linux w3m; do
      dpkg-query -W -f="\${Status}\n" "$package" | grep -qx "install ok installed"
    done
    ./bin/docpunct update debian-mail-packages
  '
