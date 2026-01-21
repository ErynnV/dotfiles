[[ $- != *i* ]] && return
# Do this first before cutting history…
# Immediate bash history
export HISTSIZE=
export HISTFILESIZE=
export HISTTIMEFORMAT="%Y-%m-%d %T "
export HISTCONTROL=ignoreboth:erasedups

stty -ixon  # Disable the CTRL+s freeze to allow backward search

shopt -s globstar
shopt -s histappend

short_pwd() {
	printf "$(pwd | sed -e "s%$HOME%\~%" -e "s%\(\.\)\?\([^\/]\)\([^\/]*\)/%\1\2/%g")"
}

RED="\[\033[31m\]"
GREEN="\[\033[32m\]"
BLUE="\[\033[34m\]"
YELLOW="\[\033[33m\]"
RESET="\[\033[39m\]"
BLUE="\[\033[34m\]"
YELLOW="\[\033[33m\]"
RESET="\[\033[39m\]"
export PS2="$ "
export PS1="${RED}[${GREEN}\u${RESET}@${BLUE}\H ${YELLOW}\$(short_pwd)${RED}]${RESET}$ "

promptcmd() {
	history -a
}

export PROMPT_COMMAND="promptcmd"

