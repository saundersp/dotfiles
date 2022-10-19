#!/usr/bin/env bash
# ~/.bash_profile
#
export TERMINAL=st
export CALIBRE_USE_DARK_PALETTE=1
[[ -f ~/.bashrc ]] && . ~/.bashrc >> /dev/null

if [[ ! ${DISPLAY} || ( ${XDG_VTNR} == 8 || ( -t 0 && $(tty) == /dev/tty1 ) ) ]]; then
	exec startx
fi
