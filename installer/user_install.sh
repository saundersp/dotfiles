#!/usr/bin/env bash

# Getting the dotfiles
cd ~/git/dotfiles
chmod +x auto.sh
chmod +x polybar/launch.sh
./auto.sh

bash ~/.bashrc
neofetchupdate

mkdir ~/Images
curl https://www.pixelstalk.net/wp-content/uploads/2016/07/HD-Astronaut-Wallpaper.jpg >> ~/Images/HD-Astronaut-Wallpaper.jpg

aur_install https://aur.archlinux.org/polybar.git

