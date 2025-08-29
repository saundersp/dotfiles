#!/bin/sh

test -f ~/.bashrc && . ~/.bashrc

# Start tmux if not started
if [ -z "$TMUX" ]; then
	command -v tmux >> /dev/null && tmux
fi
