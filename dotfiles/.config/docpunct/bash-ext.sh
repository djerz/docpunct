# shellcheck shell=bash
# Personal interactive Bash extensions.

if [ -r "$HOME/.config/docpunct/session-env.sh" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.config/docpunct/session-env.sh"
fi

# Everything below this guard is intended for interactive Bash shells only.
case $- in
    *i*) ;;
    *) return 0 ;;
esac

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/bash_completion" ]; then
    # shellcheck disable=SC1091
    . "$NVM_DIR/bash_completion"
fi
