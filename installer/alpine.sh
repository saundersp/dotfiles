#!/bin/sh

# Pre-setup steps :
# login as root
# setup-keymap LAYOUT [VARIANT]
# setup-interfaces -a
# rc-service networking start

# Configuration (tweak to your liking)
USERNAME=saundersp
HOSTNAME=myalpinebox
DISK=/dev/sda
DISK_LAST_SECTOR=
BOOT_PARTITION_INDEX=1
ROOT_PARTITION_INDEX=2
PARTITION_SEPARATOR=
PACKAGES=virtual
# Other options : virtual laptop server minimal
SWAP_SIZE=4096
CRYPTED_DISK_NAME=luks_root
TIMEZONE=Europe/London
DISK_PASSWORD=
ROOT_PASSWORD=
USER_PASSWORD=
KERNEL=edge
# Other options : lts virt edge hardened
NTP=chrony
# other options busybox openntpd chrony none

# BIOS not supported
test ! -d /sys/firmware/efi/efivars && echo 'Missing UEFI vars, exiting...' && exit 1

# Configuration checker
test -z "$DISK_PASSWORD" && echo 'Enter DISK password : ' && read -r -s DISK_PASSWORD
test -z "$ROOT_PASSWORD" && echo 'Enter ROOT password : ' && read -r -s ROOT_PASSWORD
test -z "$USER_PASSWORD" && echo 'Enter USER password : ' && read -r -s USER_PASSWORD

# Exit immediately if a command exits with a non-zero exit status
set -e

# List of disks
BOOT_PARTITION=$DISK$PARTITION_SEPARATOR$BOOT_PARTITION_INDEX
ROOT_PARTITION=$DISK$PARTITION_SEPARATOR$ROOT_PARTITION_INDEX

# Setting the timezone
setup-timezone -z "$TIMEZONE"

# Setting the hostname
setup-hostname "$HOSTNAME"

# Getting the fastest mirrors
setup-apkrepos -f

# Setting a root password
passwd << EOF
$ROOT_PASSWORD
$ROOT_PASSWORD
EOF

# Setting the NTP time synchronization
setup-ntp "$NTP"

# Partitioning the disks
apk add sfdisk
sfdisk "$DISK" << EOF
,256M,ef
,$DISK_LAST_SECTOR
EOF

# Encrypting the root partition
apk add cryptsetup
echo -n "$DISK_PASSWORD" | cryptsetup luksFormat -v "$ROOT_PARTITION"
echo -n "$DISK_PASSWORD" | cryptsetup open "$ROOT_PARTITION" "$CRYPTED_DISK_NAME"

# Formatting the partitions
mkfs.vfat -n 'UEFI Boot' "$BOOT_PARTITION"
apk add e2fsprogs
mkfs.ext4 -L Root /dev/mapper/"$CRYPTED_DISK_NAME"

# Mounting the file systems
echo "
$BOOT_PARTITION /mnt/boot vfat defaults,noatime 0 2
/dev/mapper/$CRYPTED_DISK_NAME /mnt ext4 defaults,noatime 0 1
" >> /etc/fstab
mount /dev/mapper/$CRYPTED_DISK_NAME
mkdir /mnt/boot
mount "$BOOT_PARTITION"

# Installing running systems
apk add grub-efi efibootmgr
setup-disk -s "$SWAP_SIZE" -e -k "$KERNEL" -m sys /mnt

# Fix git bug
mount /dev /mnt/dev
mount /proc /mnt/proc

echo "#!/bin/sh

# Exit immediately if a command exits with a non-zero exit status
set -e

# Enable faster startup times
sed 's/#rc_parallel=\"NO\"/rc_parallel=\"YES\"/' -i /etc/rc.conf

# Configuration of initramfs
sed -i 's/\"$/ keymap cryptsetup\"/g' /etc/mkinitfs/mkinitfs.conf
mkinitfs \$(ls /lib/modules)

# Configuration of grub
sed -i \"s;GRUB_CMDLINE_LINUX_DEFAULT=\\\"\\(.*\\)\\\";GRUB_CMDLINE_LINUX_DEFAULT=\\\"\\1 cryptroot=UUID=\$(blkid $ROOT_PARTITION | cut -d \\\" -f 2) cryptdm=$CRYPTED_DISK_NAME\\\";g\" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Switching to edge repositories mirrors
echo 'http://dl-cdn.alpinelinux.org/alpine/edge/main
http://dl-cdn.alpinelinux.org/alpine/edge/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing' > /etc/apk/repositories
apk update
apk upgrade

# Install helpers
install_pkg(){
	apk add \$@
}
install_server(){
	install_pkg neovim doas lazygit git wget unzip openssh bash-completion nodejs npm python3 \
		py3-pip ripgrep htop gcc python3-dev musl-dev g++ bash curl cryptsetup mandoc man-pages \
		mandoc-apropos less less-doc ranger libx11-dev libxft-dev fd libxext-dev tmux lazydocker \
		docker docker-compose dos2unix gdb highlight progress py3-pynvim ncdu cmake make

	# Replace sudo
	ln -s /usr/bin/doas /usr/bin/sudo

	# Enable the wheel group to use doas
	echo -e 'permit nopass :wheel\npermit nopass :wheel cmd poweroff\npermit nopass :wheel cmd reboot' > /etc/doas.d/doas.conf

	# Replace default root shell
	sed -i 's,root:/root:/bin/ash,root:/root:/bin/bash,g' /etc/passwd

	# Adding user and setting password
	adduser -s /bin/bash $USERNAME << EOF
$USER_PASSWORD
$USER_PASSWORD
EOF

	# Add the user to the wheel group
	adduser $USERNAME wheel

	# Creating custom packages source directory
	mkdir /usr/local/src

	# Installing fastfetch from source
	cd /usr/local/src
	git clone https://github.com/fastfetch-cli/fastfetch.git
	cd fastfetch
	mkdir build
	cd build
	cmake ..
	cmake --build . --target fastfetch --target flashfetch
	mv /usr/local/src/fastfetch/build/fastfetch /usr/local/bin/fastfetch

	# Installing the dotfiles
	echo \"#!/bin/sh

	# Getting the dotfiles
	mkdir ~/git
	git clone https://github.com/saundersp/dotfiles.git ~/git/dotfiles

	# Enabling the dotfiles
	cd ~/git/dotfiles
	./auto.sh server

	\" > /home/$USERNAME/install.sh
	chmod +x /home/$USERNAME/install.sh
	su -c \"/home/$USERNAME/install.sh $PACKAGES\" $USERNAME
	rm /home/$USERNAME/install.sh

	# Installing the dotfiles as root
	cd /home/$USERNAME/git/dotfiles
	./auto.sh server

	# Installing npm dependencies
	npm i -g neovim npm-check-updates
}
install_ihm(){
	install_server
	install_pkg picom xinit xset feh xclip librewolf vlc setxkbmap patch i3wm polybar harfbuzz-dev \
		libxinerama-dev xorg-server filezilla i3lock wireguard-tools pkgconf zathura zathura-pdf-mupdf \
		xf86-input-libinput eudev udev-init-scripts udev-init-scripts-openrc imagemagick libxres-dev \
		xrandr openssl-dev onetbb-dev xcb-util-image-dev opencv-dev libsixel-dev chafa-dev vips-dev

	# Installing ueberzugpp from source
	cd /usr/local/src
	git clone https://github.com/jstkdng/ueberzugpp.git
	cd ueberzugpp
	mkdir build
	cd build
	cmake -DCMAKE_BUILD_TYPE=Release ..
	cmake --build .
	mv /usr/local/src/ueberzugpp/build/ueberzugpp /usr/local/bin/ueberzugpp

	# Add pkg-config as alias of pkgconf
	ln -sf /usr/bin/pkgconf /usr/bin/pkg-config

	# Setup xorg server
	setup-xorg-base

	# Add the user to the necessary groups
	adduser $USERNAME input
	adduser $USERNAME video

	# Installing the dotfiles
	echo \"#!/bin/sh

	# Enabling the dotfiles
	cd ~/git/dotfiles
	./auto.sh remove
	./auto.sh install

	# Getting the wallpaper
	mkdir ~/Images
	cd ~/Images
	wget -q --show-progress https://www.pixelstalk.net/wp-content/uploads/2016/07/HD-Astronaut-Wallpaper.jpg
	convert -crop '2560x1440!+0+70' HD-Astronaut-Wallpaper.jpg WanderingAstronaut.png
	rm HD-Astronaut-Wallpaper.jpg
	echo -e '#!/bin/sh\nfeh --bg-fill ~/Images/WanderingAstronaut.png' > ~/.fehbg
	chmod +x ~/.fehbg
	\" > /home/$USERNAME/install.sh
	chmod +x /home/$USERNAME/install.sh
	su -c \"/home/$USERNAME/install.sh $PACKAGES\" $USERNAME
	rm /home/$USERNAME/install.sh

	cd /home/$USERNAME/git/dotfiles
	./auto.sh remove
	./auto.sh install

	# Getting the Hasklig font
	LATEST_TAG=\$(curl https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep tag_name | cut -d \\\" -f 4)
	wget -q --show-progress https://github.com/ryanoasis/nerd-fonts/releases/download/\"\$LATEST_TAG\"/Hasklig.zip
	mkdir /usr/share/fonts/Hasklig
	unzip -q Hasklig.zip -d /usr/share/fonts/Hasklig
	rm Hasklig.zip
}

# Installing the platform specific packages
case $PACKAGES in
	minimal) ;;
	server) install_server ;;
	virtual)
		install_ihm
		install_pkg virtualbox-guest-additions virtualbox-guest-additions-x11 xf86-video-vboxvideo
		rc-update add virtualbox-guest-additions default
	;;
	laptop)
		install_ihm
		install_pkg os-prober xbacklight intel-ucode wpa_supplicant ntfs-3g linux-firmware-nvidia pulseaudio \
					pulseaudio-bluez bluez pulsemixer
		# bumblebee-status-module-nvidia-prime xf86-video-intel nvidia nvidia-utils

		# Allow vlc to use nvidia gpu
		echo -e '#\!/usr/bin/env bash\nprime-run vlc' > /usr/bin/pvlc
		chmod +x /usr/bin/pvlc
	;;
esac

# Removing the nopass option in doas
sed -i '1s/nopass/persist/g' /etc/doas.d/doas.conf
" > /mnt/root/install.sh
chmod +x /mnt/root/install.sh
chroot /mnt /root/install.sh

# Cleaning leftovers
rm /mnt/root/install.sh "$0"

reboot

