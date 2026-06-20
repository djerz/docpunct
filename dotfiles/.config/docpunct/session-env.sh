# shellcheck shell=sh
# Shared login and interactive-shell environment.

case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) PATH="$HOME/.local/bin:$PATH" ;;
esac
export PATH

if [ -s "$HOME/.cargo/env" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.cargo/env"
fi

export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ] && ! command -v nvm >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    . "$NVM_DIR/nvm.sh"
fi
