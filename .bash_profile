#!/bin/bash
# ~/.bash_profile
#
TERMINAL=alacritty
[[ -f ~/.bashrc ]] && . ~/.bashrc >> /dev/null

if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
	exec startx
fi
