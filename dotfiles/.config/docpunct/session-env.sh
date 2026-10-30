# shellcheck shell=sh
# Shared login and interactive-shell environment.

case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) PATH="$HOME/.local/bin:$PATH" ;;
esac
export PATH

# WSLg supplies a display without running a Linux desktop session manager.
# Publish its environment before D-Bus activates GUI services (including the
# keyring unlock prompter). Keep explicit bus selections and SSH sessions alone.
if [ -n "${WSL_INTEROP-}${WSL_DISTRO_NAME-}" ] &&
    [ -z "${SSH_CONNECTION-}${SSH_TTY-}" ] &&
    [ -n "${DISPLAY-}${WAYLAND_DISPLAY-}" ]; then
    if [ -z "${DBUS_SESSION_BUS_ADDRESS-}" ] &&
        [ -n "${XDG_RUNTIME_DIR-}" ] && [ -S "$XDG_RUNTIME_DIR/bus" ]; then
        DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
        export DBUS_SESSION_BUS_ADDRESS
    fi
    if [ -n "${DBUS_SESSION_BUS_ADDRESS-}" ] &&
        command -v dbus-update-activation-environment >/dev/null 2>&1; then
        if ! dbus-update-activation-environment --systemd \
            DBUS_SESSION_BUS_ADDRESS DISPLAY WAYLAND_DISPLAY XAUTHORITY XDG_RUNTIME_DIR; then
            printf '%s\n' 'docpunct: could not publish WSL GUI environment to session services; keyring dialogs may fail.' >&2
        fi
    fi
fi

if [ -s "$HOME/.cargo/env" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.cargo/env"
fi

if tty_path="$(tty 2>/dev/null)" && [ -n "$tty_path" ] && [ "$tty_path" != "not a tty" ]; then
    export GPG_TTY="$tty_path"
fi

export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ] && ! command -v nvm >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    . "$NVM_DIR/nvm.sh"
fi
