#!/usr/bin/env bash
# Can't bind to /bin/sh because of export -f ...

# Pre-setup steps :
# Using the official graphical installer :
# Select language
# Select location
# Select keyboard layout
# Enter hostname
# Enter domain name
# Enter root password
# Enter new user full name
# Enter username
# Enter username password
# Select Guided partitioned encrypted LVM
# Select disk
# Select single partition
# Select yes to write changes
# Enter encryption passphrase
# Enter amount of volume group
# Confirm recap
# Select yes to write changes
# Select no to scan extra installation media
# Select package manager
# Select package mirrors : stay at the default deb.debian.org
# Enter HTTP proxy
# Select no to participate in the package usage survey
# Unselect everything in software selection
# Reboot
# Login as root
# apt update && apt upgrade -y && apt install -y curl

# Configuration (tweak to your liking)
USERNAME=saundersp
PACKAGES=virtual
# Other options : virtual laptop server
ARCH=amd64
# Other options : amd64 arm64 386

# Exit immediately if a command exits with a non-zero exit status
set -e

# Increasing the timeout of packages download
echo -e 'Acquire::http::Timeout "9999";\nAcquire::https::Timeout "9999";\nAcquire::ftp::Timeout "9999";' > /etc/apt/apt.conf

# Make apt installs non-interactive
export DEBIAN_FRONTEND=noninteractive

# Add non-free repositories to debian mirrors
sed -i 's/main/main non-free/g;s/bullseye /sid /g' /etc/apt/sources.list
apt update && apt upgrade -y

# Install helpers
install_pkg(){
	apt install -y --no-install-recommends $@
}
install_server(){
	install_pkg doas neofetch git wget unzip bash-completion nodejs npm python3 python3-pip ripgrep htop man ranger tmux \
		fd-find ccls dash docker docker-compose dos2unix gcc gdb highlight make man-db pkgconf progress flake8 python3-autopep8 \
		python3-pynvim apt-file g++
	ln -s /usr/bin/fdfind /usr/bin/fd
	ln -s /usr/bin/python3 /usr/bin/python
	ln -sf /bin/dash /bin/sh

	# Installing neovim
	wget -q --show-progress https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.deb -O /tmp/nvim-linux64.deb
	install_pkg /tmp/nvim-linux64.deb
	rm /tmp/nvim-linux64.deb
	apt remove -y vim-common vim-tiny

	# Enable the wheel group to use doas and allow users to poweroff and reboot
	echo -e 'permit nopass :wheel\npermit nopass :wheel cmd poweroff\npermit nopass :wheel cmd reboot' > /etc/doas.conf

	# Replace sudo
	ln -s /usr/bin/doas /usr/bin/sudo

	# Add root and user to the wheel group
	addgroup wheel
	usermod -aG wheel root
	usermod -aG wheel "$USERNAME"

	# Installing go
	local GO_LINK=https://go.dev/dl/
	local LATEST_GO_VERSION
	LATEST_GO_VERSION=$(curl $GO_LINK?mode=json | grep version | sed 2,202000d | cut -d \" -f 4)
	local GO_FILE=$LATEST_GO_VERSION.linux-$ARCH.tar.gz
	wget "$GO_LINK$GO_FILE"
	tar -C /usr/local -xzf "$GO_FILE"
	ln -s /usr/local/go/bin/go /usr/bin/go
	rm "$GO_FILE"

	# Compiling lazygit
	cd /usr/local/src
	git clone https://github.com/jesseduffield/lazygit.git
	cd lazygit
	install_pkg libstdc++-11-dev
	go install -buildvcs=false
	mv /root/go/bin/lazygit /usr/bin/lazygit

	# Compiling lazydocker
	cd /usr/local/src
	git clone https://github.com/jesseduffield/lazydocker.git
	cd lazydocker
	go install -buildvcs=false
	mv /root/go/bin/lazydocker /usr/bin/lazydocker

	# Installing npm dependencies
	npm i -g neovim npm-check-updates
}
install_ihm(){
	install_server
	install_pkg picom xinit xserver-xorg-core x11-xserver-utils feh xclip vlc polybar xserver-xorg-input-kbd \
		xserver-xorg-input-mouse xserver-xorg-input-libinput libxinerama-dev autokey-qt calibre filezilla wireguard-tools zathura \
		imagemagick i3-wm patch libxft-dev libharfbuzz-dev ueberzug gnupg

	wget -O- https://deb.librewolf.net/keyring.gpg | gpg --dearmor -o /usr/share/keyrings/librewolf.gpg

	tee /etc/apt/sources.list.d/librewolf.sources << EOF > /dev/null
Types: deb
URIs: https://deb.librewolf.net
Suites: focal
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/librewolf.gpg
EOF
	apt update
	install_pkg librewolf

	# Getting the Hasklig font
	LATEST_TAG=$(curl https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep tag_name | cut -d \" -f 4)
	wget -q --show-progress https://github.com/ryanoasis/nerd-fonts/releases/download/"$LATEST_TAG"/Hasklig.zip
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
	./auto.sh "$1"
	sudo bash auto.sh "$1"

	# Getting the wallpaper
	mkdir ~/Images
	cd ~/Images
	wget -q --show-progress https://www.pixelstalk.net/wp-content/uploads/2016/07/HD-Astronaut-Wallpaper.jpg
	convert -crop '2560x1440!+0+70' HD-Astronaut-Wallpaper.jpg WanderingAstronaut.png
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
		install_pkg virtualbox-guest-additions-iso
	;;
	laptop)
		install_ihm
		install_pkg os-prober xbacklight
		# bumblebee-status-module-nvidia-prime ntfs-3g ucode-intel wpa_supplicant pulseaudio
		# xf86-video-intel pulseaudio-module-bluetooth bluez nvidia nvidia-utils pulsemixer

		# Allow vlc to use nvidia gpu
		echo -e '#\!/usr/bin/env bash\nprime-run vlc' > /usr/bin/pvlc
		chmod +x /usr/bin/pvlc
	;;
esac

# Installing the dotfiles
su "$USERNAME" -c "install_dotfiles $PACKAGES"

# Removing the nopass option in doas
sed -i '1s/nopass/persist/g' /etc/doas.conf

# Cleaning leftovers
cd /root && rm "$0"
reboot

