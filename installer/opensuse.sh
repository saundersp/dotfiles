#!/usr/bin/env bash

# Pre-setup steps :
# Using the official graphical installer :
# If Wifi setup wifi
# Select language and keyboard layout
# Activate default online repositories
# Select server system role
# Select expert partitioner with the option "Start with Existing Partitions"
# Require at least 3 partitions :
#| Format type | Device type               | Size     | Is encrypted | Mounting point |
#| FAT32       | EFI Boot Partition        | 256MB    | No           | /boot          |
#| FAT32       | EFI Boot Partition        | 256MB    | No           | /boot/efi      |
#| ext4        | Data and ISV Applications | Remaning | Yes          | /              |
# Select Clock and Time Zone
# Create local user
# Confirm install

# Configuration (tweak to your liking)
USERNAME=saundersp
PACKAGES=virtual
# Other options : virtual laptop server

# Exit immediately if a command exits with a non-zero exit status
set -e

# Adding missings mirrors
zypper addrepo -G https://download.opensuse.org/repositories/security/openSUSE_Tumbleweed/security.repo               # For opendoas
zypper addrepo -G https://download.opensuse.org/repositories/home:Dead_Mozay/openSUSE_Tumbleweed/home:Dead_Mozay.repo # For lazygit
refresh

# Disable the installation of recommended packages
sed -i 's/# solver.onlyRequires = false/solver.onlyRequires = true/g' /etc/zypp/zypp.conf

# Removing unwanted packages
zypper remove -y sudo nano vim

# Install helpers
install_pkg(){
	zypper install -y $@
}
install_server(){
	install_pkg git neofetch neovim unzip bash-completion nodejs npm python3 python3-pip ripgrep htop lazygit opendoas

	# Enable the wheel group to use doas and allow user to poweroff and reboot
	echo -e 'permit nopass :wheel\npermit nopass :wheel cmd poweroff\npermit nopass :wheel cmd reboot' > /etc/doas.conf

	# Replace sudo
	ln -s /usr/bin/doas /usr/bin/sudo

	# Installing npm dependencies
	npm i -g neovim npm-check-updates

	# Installing pip dependencies
	pip install pynvim autopep8 flake8

	# Adding user to wheel groups
	usermod -aG wheel $USERNAME
	usermod -aG wheel root
}
install_ihm(){
	install_server
	install_pkg xinit xorg-x11-server xset polybar alacritty i3-gaps dmenu picom feh keepass xclip firefox vlc xrandr xf86-input-keyboard xf86-input-libinput xf86-input-mouse

	# Getting the Hasklig font
	wget -q --show-progress https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Hasklig.zip
	mkdir -p /usr/share/fonts/Hasklig
	unzip -q Hasklig.zip -d /usr/share/fonts/Hasklig
	rm Hasklig.zip
}
install_dotfiles(){
	# Getting the dotfiles
	mkdir ~/git
	git clone https://github.com/saundersp/dotfiles.git ~/git/dotfiles

	# Enabling the dotfiles
	cd ~/git/dotfiles
	./auto.sh $@
	sudo bash auto.sh $@

	# Getting the wallpaper
	mkdir ~/Images
	cd ~/Images
	wget -q --show-progress https://www.pixelstalk.net/wp-content/uploads/2016/07/HD-Astronaut-Wallpaper.jpg
}
export -f install_dotfiles

# Installing the platform specific packages
case $PACKAGES in
	server) install_server ;;
	virtual)
		install_ihm
		install_pkg virtualbox-guest-tools
	;;
	laptop)
		install_ihm
		install_pkg os-prober brightnessctl bumblebee-status-module-nvidia-prime ntfs-3g ucode-intel wpa_supplicant pulseaudio \
					xf86-video-intel pulseaudio-module-bluetooth bluez #nvidia nvidia-utils nvidia-settings pulsemixer

		# Allow vlc to use nvidia gpu
		echo -e '#\!/usr/bin/env bash\nprime-run vlc' > /usr/bin/pvlc
		chmod +x /usr/bin/pvlc

		# Allow user to use brightnessctl
		echo 'permit nopass :wheel cmd brightnessctl' >> /etc/doas.conf
	;;
esac

# Installing the dotfiles
su $USERNAME -c install_dotfiles $PACKAGES

# Removing the nopass option in doas
sed -i '1s/nopass/persist/g' /etc/doas.conf

# Cleaning leftovers
rm $0

