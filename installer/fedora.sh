#!/usr/bin/env bash
# Can't bind to /bin/sh because of export -f ...

# Pre-setup steps :
# /!\ Use the 'Everything' Fedora alternative iso image
# Using the official graphical installer :
# Select language
# Select keyboard layout
# Select time & date
# Enable root account
# Create user
# Select system destination
# Select software : minimal install
# Install and reboot
# Login as root

# Configuration (tweak to your liking)
USERNAME=saundersp
PACKAGES=virtual
# Other options : virtual laptop server

# Exit immediately if a command exits with a non-zero exit status
set -e

# Removing unused programs
find -- / -name "*sudo*" -delete | true
dnf remove -y sudo vi

# Install helpers
install_pkg(){
	dnf install -y $@
}
install_server(){
	# Setup docker repository
	dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

	# Installing lazygit
	dnf copr enable atim/lazygit -y
	# Installing lazydocker
	dnf copr enable atim/lazydocker -y

	install_pkg fastfetch neovim python3 python3-pip wget unzip bash-completion nodejs npm ripgrep btop opendoas git yazi tmux dash \
		dnf-plugins-core docker-ce docker-ce-cli containerd.io docker-compose-plugin dos2unix fd-find gcc gcc-c++ gdb make highlight lazygit \
		lazydocker man-db wireguard-tools patch pkgconf progress python3-neovim ncdu golang

	# Use dash instead of bash as default shell
	ln -sf /bin/dash /bin/sh

	# Enable the wheel group to use doas and allow user to poweroff and reboot
	echo -e 'permit nopass :wheel\npermit nopass :wheel cmd poweroff\npermit nopass :wheel cmd reboot' > /etc/doas.conf

	# Replace sudo
	ln -s /usr/bin/doas /usr/bin/sudo

	# Installing npm dependencies
	npm i -g npm-check-updates

	# Adding user to wheel groups
	usermod -aG wheel "$USERNAME"
	usermod -aG wheel root
}
install_ihm(){
	install_server
	install_pkg i3 xorg-x11-xinit xset polybar picom feh alacritty xclip xorg-x11-server-Xorg python-xlib autokey-qt calibre i3lock \
		torbrowser-launcher zathura zathura-pdf-mupdf python-devel libX11-devel libXext-devel libXft-devel libXinerama-devel ImageMagick \
		libXres-devel tor vlc dbus-daemon flatpak

	# Enable the Flathub remote
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

	# Installing spotify
	flatpak install -y flathub com.spotify.Client
	echo -e '#!/bin/sh\nflatpak run com.spotify.Client' > /usr/local/bin/spotify
	chmod +x /usr/local/bin/spotify

	# Installing ueberzugpp (fedora version pedantic ?)
	dnf config-manager --add-repo https://download.opensuse.org/repositories/home:justkidding/Fedora_40/home:justkidding.repo
	install_pkg ueberzugpp

	# Installing librewolf
	rpm --import https://keys.openpgp.org/vks/v1/by-fingerprint/034F7776EF5E0C613D2F7934D29FBD5F93C0CFC3
	dnf config-manager --add-repo https://rpm.librewolf.net
	install_pkg librewolf

	# Installing pulsemixer
	git clone https://github.com/GeorgeFilipkin/pulsemixer.git /usr/local/src/pulsemixer
	ln -sfv /usr/local/src/pulsemixer/pulsemixer /usr/local/bin/pulsemixer

	# Getting the Hasklig font
	LATEST_TAG=$(curl https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep tag_name | cut -d \" -f 4)
	wget https://github.com/ryanoasis/nerd-fonts/releases/download/"$LATEST_TAG"/Hasklig.zip
	mkdir -p /usr/share/fonts/Hasklig
	unzip -q Hasklig.zip -d /usr/share/fonts/Hasklig
	echo "$LATEST_TAG" > /usr/share/fonts/Hasklig/VERSION
	rm Hasklig.zip
}
install_dotfiles(){
	# Removing bash profile that blocks default .profile
	rm -v ~/.bash_profile ~/.bash_logout

	# Getting the dotfiles
	mkdir ~/git
	git clone https://github.com/saundersp/dotfiles.git ~/git/dotfiles

	# Enabling the dotfiles
	cd ~/git/dotfiles
	./auto.sh "$1"
	sudo bash auto.sh "$1"

	# Getting the wallpaper
	mkdir ~/Images
	cd ~/Images
	wget https://www.pixelstalk.net/wp-content/uploads/2016/07/HD-Astronaut-Wallpaper.jpg
	magick convert -crop '2560x1440!+0+70' HD-Astronaut-Wallpaper.jpg WanderingAstronaut.png
	rm HD-Astronaut-Wallpaper.jpg
	echo -e '#!/bin/sh\nfeh --bg-fill ~/Images/WanderingAstronaut.png' > ~/.fehbg
	chmod +x ~/.fehbg
}
export -f install_dotfiles

# Installing the platform specific packages
case $PACKAGES in
	server) install_server ;;
	virtual)
		install_ihm
		install_pkg virtualbox-guest-additions
	;;
	laptop)
		install_ihm
		install_pkg os-prober brightnessctl ntfs-3g wpa_supplicant pulseaudio bluez-tools pulseaudio-module-bluetooth xorg-x11-drv-intel
	;;
esac

# Installing the dotfiles
su "$USERNAME" -c "install_dotfiles $PACKAGES"

# Removing the nopass option in doas
sed -i '1s/nopass/persist/g' /etc/doas.conf

# Cleaning leftovers
rm "$0"

reboot

