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
# Select yes to configure the package manager
# Select package manager mirror location
# Select package mirrors : stay at the default deb.debian.org
# Enter HTTP proxy (leave blank if none)
# Select no to participate in the package usage survey
# Unselect everything in software selection
# Reboot
# Login as root
# Remove cdrom source in /etc/apt/sources.list
# apt update && apt upgrade -y && apt install -y --no-install-recommends curl ca-certificates

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
	install_pkg doas git wget unzip bash-completion nodejs npm python3 python3-pip ripgrep btop man ranger tmux fd-find dash docker \
		docker-compose dos2unix gcc gdb highlight make man-db pkgconf progress python3-pynvim apt-file g++ cmake ncdu
	ln -s /usr/bin/fdfind /usr/bin/fd
	ln -s /usr/bin/python3 /usr/bin/python
	ln -sf /bin/dash /bin/sh

	# Installing fastfetch from source
	cd /usr/local/src
	git clone --depth 1 https://github.com/fastfetch-cli/fastfetch.git
	cd fastfetch
	cmake -B build
	cmake --build build --target fastfetch --target flashfetch -j "$(nproc)"
	mv build/fastfetch /usr/local/bin/fastfetch
	rm -r build

	# Installing neovim dependencies
	install_pkg gettext

	# Installing neovim from source
	cd /usr/local/src
	git clone --depth 1 https://github.com/neovim/neovim.git
	cd neovim
	make CMAKE_BUILD_TYPE=Release -j "$(nproc)" -l "$(nproc)"
	make install clean
	rm -r build .deps
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
	LATEST_GO_VERSION=$(curl "$GO_LINK"?mode=json | grep version | sed 2,202000d | cut -d \" -f 4)
	local GO_FILE="$LATEST_GO_VERSION".linux-"$ARCH".tar.gz
	wget "$GO_LINK$GO_FILE"
	tar -C /usr/local -xzf "$GO_FILE"
	ln -s /usr/local/go/bin/go /usr/bin/go
	rm "$GO_FILE"

	# Installing lazygit dependencies
	install_pkg libstdc++-11-dev

	# Compiling lazynpm and lazydocker
	for package in git npm docker; do
		if [ ! -d /usr/local/src/lazy"$package" ]; then
			cd /usr/local/src
			git clone --depth 1 https://github.com/jesseduffield/lazy"$package".git
			cd lazy"$package"
			go install -buildvcs=false
			mv /root/go/bin/lazy"$package" /usr/local/bin/lazy"$package"
		fi
	done
	cd

	# Cleaning go cache files
	rm -rf /root/go

	# Installing npm dependencies
	npm i -g npm-check-updates
}
install_ihm(){
	install_server
	install_pkg picom xinit xserver-xorg-core x11-xserver-utils feh xclip vlc polybar xserver-xorg-input-kbd xserver-xorg-input-mouse \
		xserver-xorg-input-libinput libxinerama-dev autokey-qt calibre filezilla wireguard-tools zathura imagemagick i3-wm patch \
		libxft-dev libharfbuzz-dev gnupg

	wget -O- https://deb.librewolf.net/keyring.gpg | gpg --dearmor -o /usr/share/keyrings/librewolf.gpg

	install_pkg extrepo
	extrepo enable librewolf
	apt update
	install_pkg librewolf

	# Installing ueberzugpp dependencies
	install_pkg libtbb-dev libxcb-image0-dev libxcb-res0-dev libopencv-dev libvips-dev libsixel-dev libchafa-dev

	# Installing ueberzugpp from source
	cd /usr/local/src
	git clone --depth 1 https://github.com/jstkdng/ueberzugpp.git
	cd ueberzugpp
	cmake -DCMAKE_BUILD_TYPE=Release -B build
	cmake --build build -j "$(nproc)"
	mv /usr/local/src/ueberzugpp/build/ueberzugpp /usr/local/bin/ueberzugpp
	mv /usr/local/src/ueberzugpp/build/ueberzug /usr/local/bin/ueberzug
	rm -r build

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
	git clone --depth 1 https://github.com/saundersp/dotfiles.git ~/git/dotfiles

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
		install_pkg os-prober brightnessctl
		# bumblebee-status-module-nvidia-prime ntfs-3g ucode-intel wpa_supplicant pulseaudio
		# xf86-video-intel pulseaudio-module-bluetooth bluez nvidia nvidia-utils pulsemixer
	;;
esac

# Installing the dotfiles
su "$USERNAME" -c "install_dotfiles $PACKAGES"

# Removing the nopass option in doas
sed -i '1s/nopass/persist/g' /etc/doas.conf

# Cleaning leftovers
cd /root && rm "$0"
reboot

