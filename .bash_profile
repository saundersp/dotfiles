#!/bin/sh
# Some global XDG variables
command -v st >> /dev/null && export TERMINAL=st
command -v librewolf >> /dev/null && export BROWSER=librewolf
command -v calibre >> /dev/null && export CALIBRE_USE_DARK_PALETTE=1
test -d /opt/cuda && export CUDA_HOME=/opt/cuda
test -f ~/.bashrc && . ~/.bashrc

if [ -z "$SSH_CONNECTION" ] && [ ! "$DISPLAY" ] || [ "$XDG_VTNR" = 8 ] || [ "$(tty)" = /dev/tty1 ] && [ "$TERM" != "st-256color" ]; then
	startx
fi
