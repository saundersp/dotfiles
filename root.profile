#!/bin/sh

test -f ~/.bashrc && . ~/.bashrc

# Set the tty keyboard typematic delay and rate
test -z "$DISPLAY" && command -v kbdrate >> /dev/null && kbdrate --silent -d 250 -r 30.0

# Start tmux if not started
if [ -z "$TMUX" ]; then
	command -v tmux >> /dev/null && tmux
fi
