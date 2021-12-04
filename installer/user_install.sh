#!/usr/bin/env bash

source ~/git/dotfiles/installer/config.conf

# Getting the dotfiles
cd ~/git/dotfiles
chmod +x auto.sh
chmod +x polybar/launch.sh
./auto.sh

mkdir ~/Images
curl https://www.pixelstalk.net/wp-content/uploads/2016/07/HD-Astronaut-Wallpaper.jpg > ~/Images/HD-Astronaut-Wallpaper.jpg

aur_install(){
	local PACKAGE_NAME=$(basename $1 .git)
	git clone $1 ~/aur/$PACKAGE_NAME
	cd ~/aur/$PACKAGE_NAME
	makepkg -sri
}

aur_install https://aur.archlinux.org/polybar.git
if [ $PACKAGES == "laptop" ]; then
	aur_install https://aur.archlinux.org/davmail.git
	aur_install https://aur.archlitnux.org/tor-browser.git
	aur_install https://aur.archlinux.org/font-manager.git
fi

