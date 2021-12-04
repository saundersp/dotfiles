#!/usr/bin/env bash

# Getting the dotfiles
cd ~/git/dotfiles
chmod +x auto.sh
chmod +x polybar/launch.sh
./auto.sh

mkdir ~/Images
curl https://www.pixelstalk.net/wp-content/uploads/2016/07/HD-Astronaut-Wallpaper.jpg > ~/Images/HD-Astronaut-Wallpaper.jpg

git clone https://aur.archlinux.org/polybar.git ~/aur/polybar
cd ~/aur/polybar
makepkg -sri

