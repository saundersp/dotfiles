#!/usr/bin/env bash
# Some global XDG variables
command -v st >> /dev/null && export TERMINAL=st
command -v librewolf >> /dev/null && export BROWSER=librewolf
command -v calibre >> /dev/null && export CALIBRE_USE_DARK_PALETTE=1
test -d /opt/cuda && export CUDA_HOME=/opt/cuda
[[ -f ~/.bashrc ]] && . ~/.bashrc >> /dev/null

if [[ ! ${DISPLAY} || ( ${XDG_VTNR} == 8 || ( -t 0 && $(tty) == /dev/tty1 ) ) ]]; then
	exec startx
fi
