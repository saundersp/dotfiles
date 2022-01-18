#!/usr/bin/env bash

# Disable screensaver
xset s off &
xset s noblank &
xset -dpms &
# Starting the compositor
picom -b -f -i 0.95 &
# Set the wallpaper
feh --bg-fill $HOME/Images/HD-Astronaut-Wallpaper.jpg &
# Set the keyboard repeat delay to 150ms and rate to 80 repeat/s
xset r rate 150 80 &
# Set the keyboard layout to french
setxkbmap fr &
exec i3
