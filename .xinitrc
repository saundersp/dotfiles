#!/bin/sh

# Disable screensaver
xset s off &
# Disable the control Energy Star features
xset -dpms &
# Starting the compositor
picom -b &
# Set the wallpaper
"$HOME"/.fehbg &
# Set the keyboard repeat delay to 150ms and rate to 80 repeat/s
xset r rate 150 80 &
# Set the keyboard layout to french
setxkbmap fr &
# Disable mouse acceleration
xset m 0 0 &
# Load colour ressources
xrdb -load "$XDG_CONFIG_HOME/X11/Xresources"
exec dbus-run-session i3
