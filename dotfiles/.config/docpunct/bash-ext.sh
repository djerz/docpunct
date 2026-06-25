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

alias g="git"
alias vim="nvim"

# Check for various OS openers. Quit as soon as we find one that works.
#for opener in browser-exec xdg-open cmd.exe cygstart "start" open; do
#	if command -v $opener >/dev/null 2>&1; then
#		if [[ "$opener" == "cmd.exe" ]]; then
#			# shellcheck disable=SC2139
#			alias open="$opener /c start";
#		else
#			# shellcheck disable=SC2139
#			alias open="$opener";
#		fi
#		break;
#	fi
#done

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# Enable aliases to be sudo’ed
alias sudo='sudo '

# Get week number
alias week='date +%V'

# Stopwatch
alias timer='echo "Timer started. Stop with Ctrl-D." && date && time cat && date'

alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

pbcopy() {
	stdin=$(</dev/stdin);
	pbcopy="$(which pbcopy)";
	if [[ -n "$pbcopy" ]]; then
		echo "$stdin" | "$pbcopy"
	else
		echo "$stdin" | xclip -selection clipboard
	fi
}
pbpaste() {
	pbpaste="$(which pbpaste)";
	if [[ -n "$pbpaste" ]]; then
		"$pbpaste"
	else
		xclip -selection clipboard
	fi
}

export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/bash_completion" ]; then
    # shellcheck disable=SC1091
    . "$NVM_DIR/bash_completion"
fi

winquote_if_needed() {
    case "$1" in
        *[[:space:]]*) printf '"%s"' "$1" ;;
        *) printf '%s' "$1" ;;
    esac
}

runwin() {
    local file="$1"
    shift

    local abs abs_dir base win_dir ext cmd
    abs=$(realpath "$file") || return 1
    abs_dir=$(dirname "$abs")
    base=$(basename "$abs")
    win_dir=$(wslpath -w "$abs_dir")
    ext="${base##*.}"
    ext="${ext,,}"

    case "$ext" in
        bat|cmd)
            cmd="cd /d $(winquote_if_needed "$win_dir") && call $(winquote_if_needed "$base")"

            for arg in "$@"; do
                cmd="$cmd $(winquote_if_needed "$arg")"
            done

            echo "[runwin] cmd=$cmd"
            cmd.exe /c "$cmd"
            ;;

        ps1)
            local win_ps1
            win_ps1=$(wslpath -w "$abs")

            echo "[runwin] ps1=$win_ps1"
            powershell.exe -NoProfile -ExecutionPolicy Bypass \
                -File "$(winquote_if_needed "$win_ps1")" "$@"
            ;;

        *)
            echo "Unsupported extension: .$ext" >&2
            return 1
            ;;
    esac
}
