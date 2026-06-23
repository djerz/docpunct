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

alias vim="nvim"

# Check for various OS openers. Quit as soon as we find one that works.
for opener in browser-exec xdg-open cmd.exe cygstart "start" open; do
	if command -v $opener >/dev/null 2>&1; then
		if [[ "$opener" == "cmd.exe" ]]; then
			# shellcheck disable=SC2139
			alias open="$opener /c start";
		else
			# shellcheck disable=SC2139
			alias open="$opener";
		fi
		break;
	fi
done

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
