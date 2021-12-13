#!/bin/bash
# ~/.bash_profile
#
TERMINAL=alacritty
[[ -f ~/.bashrc ]] && . ~/.bashrc >> /dev/null

if [[ ! ${DISPLAY} || ( ${XDG_VTNR} == 8 || ( -t 0 && $(tty) == /dev/tty1 ) ) ]]; then
	exec startx
fi
