#!/usr/bin/env bash
# Set the tty keyboard typematic delay and rate
kbdrate --silent -d 200 -r 30.0 &
# Set the keyboard layout to french
setxkbmap fr &
clear
[[ -f ~/.bashrc ]] && . ~/.bashrc
