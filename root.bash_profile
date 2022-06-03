#!/bin/sh
# Set the tty keyboard typematic delay and rate
kbdrate --silent -d 250 -r 30.0 &
clear
test -f ~/.bashrc && . ~/.bashrc
test "$TERM" != "screen" && tmux
# Dirty way to not return exit code 1
printf ""
