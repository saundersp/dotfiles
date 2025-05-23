#!/usr/bin/env bash
# Can't bind to /bin/sh because of export -f ...

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
# Log as root

# Configuration (tweak to your liking)
USERNAME=saundersp
PACKAGES=virtual
# Other options : virtual laptop server

# Exit immediately if a command exits with a non-zero exit status
set -e

# Disable the installation of recommended packages
sed -i 's/# solver.onlyRequires = false/solver.onlyRequires = true/g' /etc/zypp/zypp.conf

# Removing unwanted packages
zypper remove -y sudo nano vim

# Install helpers
install_pkg(){
	zypper install -n -y $@
}
install_server(){
	# Adding missings mirrors
	zypper addrepo -G https://download.opensuse.org/repositories/security/openSUSE_Tumbleweed/security.repo               # For opendoas
	zypper addrepo -G https://download.opensuse.org/repositories/home:Dead_Mozay/openSUSE_Tumbleweed/home:Dead_Mozay.repo # For lazygit
	zypper addrepo -G https://download.opensuse.org/repositories/home:lemmy04/openSUSE_Tumbleweed/home:lemmy04.repo       # For lazydocker
	zypper refresh
	install_pkg git fastfetch neovim unzip bash-completion nodejs-default npm-default python312 python312-pip ripgrep btop lazygit \
		opendoas yazi lazydocker patch gcc gcc-c++ make fd tmux ccls dash docker docker-compose dos2unix gdb highlight python312-neovim \
		go ncdu wireguard-tools

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
	install_pkg xinit xorg-x11-server xset polybar i3 picom feh xclip mpv xrandr xf86-input-libinput libX11-devel libXinerama-devel \
		libXft-devel harfbuzz-devel ncurses-devel ueberzugpp python312-python-xlib calibre pkgconf filezilla i3lock zathura \
		zathura-plugin-pdf-mupdf ImageMagick python312-pulsemixer pulseaudio pulseaudio-utils spotify-client

	# Installing librewolf
	rpm --import https://rpm.librewolf.net/pubkey.gpg
	zypper ar -ef https://rpm.librewolf.net librewolf
	zypper refresh
	install_pkg librewolf

	# Adding missing c99 executable
	printf '#!/bin/sh\n\nfl="-std=c99"\nfor opt; do\n  case "$opt" in\n\t-std=c99|-std=iso9899:1999) fl="";;\n\t-std=*) echo "`basename $0` called with non ISO C99 option $opt" >&2\texit 1;;\n\tesac\ndone\nexec gcc $fl ${1+"$@"}' > /usr/bin/c99
	chmod +x /usr/bin/c99

	# Getting the Hasklig font
	LATEST_TAG=$(curl https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep tag_name | cut -d \" -f 4)
	wget -q --show-progress https://github.com/ryanoasis/nerd-fonts/releases/download/"$LATEST_TAG"/Hasklig.zip
	mkdir -p /usr/share/fonts/Hasklig
	unzip -q Hasklig.zip -d /usr/share/fonts/Hasklig
	echo "$LATEST_TAG" > /usr/share/fonts/Hasklig/VERSION
	rm Hasklig.zip
}
install_dotfiles(){
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
	wget -q --show-progress https://www.pixelstalk.net/wp-content/uploads/2016/07/HD-Astronaut-Wallpaper.jpg
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
		install_pkg virtualbox-guest-tools
	;;
	laptop)
		install_ihm
		install_pkg os-prober brightnessctl bumblebee-status-module-nvidia-prime ntfs-3g ucode-intel wpa_supplicant xf86-video-intel \
			pulseaudio-module-bluetooth bluez nvidia-driver
	;;
esac

# Installing the dotfiles
su "$USERNAME" -c "install_dotfiles $PACKAGES"

# Removing the nopass option in doas
sed -i '1s/nopass/persist/g' /etc/doas.conf

# Cleaning leftovers
rm "$0"
reboot

