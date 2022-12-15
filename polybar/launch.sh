#!/bin/sh

# Terminate already running bar instances
pkill polybar

# Launch Polybar, using default config location ~/.config/polybar/config
polybar --config="$XDG_CONFIG_HOME"/polybar/config.ini mybar 2>&1 | tee -a /tmp/polybar.log &

echo "Polybar launched..."
