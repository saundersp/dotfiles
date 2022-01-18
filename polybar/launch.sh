#!/bin/bash

# Terminate already running bar instances
pkill polybar

# Launch Polybar, using default config location ~/.config/polybar/config
polybar mybar 2>&1 | tee -a /tmp/polybar.log & disown

echo "Polybar launched..."
