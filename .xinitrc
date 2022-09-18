#!/usr/bin/env bash

# Disable screensaver
xset s off &
# Disable the control Energy Star features
xset -dpms &
# Starting the compositor
picom -b -f -i 0.9 &
# Set the wallpaper
$HOME/.fehbg &
# Set the keyboard repeat delay to 150ms and rate to 80 repeat/s
xset r rate 150 80 &
# Set the keyboard layout to french
setxkbmap fr &
xrdb -load "$XDG_CONFIG_HOME/X11/Xresources"
exec i3
