#!/bin/sh

test -f ~/.bashrc && . ~/.bashrc

if [ -z "$SSH_CONNECTION" ] && [ ! "$DISPLAY" ] || [ "$XDG_VTNR" = 8 ] || [ "$(tty)" = /dev/tty1 ]; then
	startx
fi
