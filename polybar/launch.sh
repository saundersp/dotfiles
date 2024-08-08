#!/bin/sh

# Terminate already running bars instances
pkill polybar

if command -v xrandr >> /dev/null; then
	for monitor in $(xrandr --query | grep ' connected' | cut -d ' ' -f1); do
		MONITOR="$monitor" polybar --reload my_bar 2>&1 | tee -a /tmp/polybar_"$monitor".log &
		echo "Polybar launched on monitor $monitor"
	done
else
	# Launch Polybar, using default config location ~/.config/polybar/config
	polybar --reload my_bar 2>&1 | tee -a /tmp/polybar.log &
	echo 'Polybar launched...'
fi
