#!/bin/sh

local userresources usermodmap sysresources sysmodmap
userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and key maps
test -f "$sysresources"  && xrdb -merge $sysresources
test -f "$sysmodmap"     && xmodmap $sysmodmap
test -f "$userresources" && xrdb -merge "$userresources"
test -f "$usermodmap"    && xmodmap "$usermodmap"

# start some nice programs
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
	for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
		[ -x "$f" ] && . "$f"
	done
	unset f
fi

# Disable screensaver
xset s off &
xset s noblank &
xset -dpms &
# Starting the compositor
picom -b -f -i 0.95 &
# Set the wallpaper
feh --bg-fill $HOME/Images/HD-Astronaut-Wallpaper.jpg &
# Set the keyboard repeat delay to 200ms and rate to 80 repeat/s
xset r rate 200 80 &
# Set the keyboard layout to french
setxkbmap fr &
exec i3
