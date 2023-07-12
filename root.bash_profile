#!/bin/sh
test -f ~/.bashrc && . ~/.bashrc
if [ "$TERM" != "st-256color" ]; then
	# Set the tty keyboard typematic delay and rate
	command -v kbdrate >> /dev/null && kbdrate --silent -d 250 -r 30.0
	command -v tmux >> /dev/null && tmux
fi
