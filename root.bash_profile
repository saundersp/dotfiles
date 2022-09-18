#!/bin/sh
test -f ~/.bashrc && . ~/.bashrc
if [[ "$TERM" != "st-256color" ]]; then
	# Set the tty keyboard typematic delay and rate
	kbdrate --silent -d 250 -r 30.0
	tmux
fi
