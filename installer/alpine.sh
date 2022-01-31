#!/usr/bin/env ash

# Pre-setup steps :
# login as root
# setup-keymap fr fr
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
GRUB_ID=GRUB
KEYMAP=fr
LOCALE=en_US
TIMEZONE=Europe/London
DISK_PASSWORD=
ROOT_PASSWORD=
USER_PASSWORD=
KERNEL=lts
# Other options : lts virt edge hardened
NTP=chrony
# other options busybox openntpd chrony none

# Configuration checker
test -z $DISK_PASSWORD && echo 'Enter DISK password : ' && read -s DISK_PASSWORD
test -z $ROOT_PASSWORD && echo 'Enter ROOT password : ' && read -s ROOT_PASSWORD
test -z $USER_PASSWORD && echo 'Enter USER password : ' && read -s USER_PASSWORD

# Exit immediately if a command exits with a non-zero exit status
set -e

# List of disks
BOOT_PARTITION=$DISK$PARTITION_SEPARATOR$BOOT_PARTITION_INDEX
ROOT_PARTITION=$DISK$PARTITION_SEPARATOR$ROOT_PARTITION_INDEX

# Setting the timezone
setup-timezone -z $TIMEZONE

# Setting the hostname
setup-hostname $HOSTNAME

# Getting the fastest mirrors
setup-apkrepos -f

# Setting a root password
passwd << EOF
$ROOT_PASSWORD
$ROOT_PASSWORD
EOF

# Setting the NTP time synchronization
setup-ntp -c $NTP

# Partitioning the disks
apk add sfdisk 1>&2 | true
sfdisk $DISK << EOF
,256M,ef
,$DISK_LAST_SECTOR
EOF

# Encrypting the root partition
apk add cryptsetup 1>&2 | true
echo -n $DISK_PASSWORD | cryptsetup luksFormat -v $ROOT_PARTITION
echo -n $DISK_PASSWORD | cryptsetup open $ROOT_PARTITION $CRYPTED_DISK_NAME

# Formatting the partitions
mkfs.vfat -n 'UEFI Boot' $BOOT_PARTITION
apk add e2fsprogs 1>&2 | true
mkfs.ext4 -L Root /dev/mapper/$CRYPTED_DISK_NAME

# Mounting the file systems
echo "
$BOOT_PARTITION /mnt/boot vfat defaults,noatime 0 2
/dev/mapper/$CRYPTED_DISK_NAME /mnt ext4 noatime 0 1
" >> /etc/fstab
mount /dev/mapper/$CRYPTED_DISK_NAME
mkdir /mnt/boot
mount $BOOT_PARTITION

# Installing running systems
apk add grub-efi efibootmgr 1>&2 | true
BOOTLOADER=grub
USE_EFI=1
setup-disk -s $SWAP_SIZE -e -k $KERNEL -m sys /mnt

# Fix git bug
mount /dev /mnt/dev

echo "#!/usr/bin/env ash

# Exit immediately if a command exits with a non-zero exit status
set -e

# Configuration of initramfs
sed -i 's/\"\$/ keymap cryptsetup\"/g' /etc/mkinitfs/mkinitfs.conf
mkinitfs \$(ls /lib/modules)

# Configuration of grub
sed -i 's;GRUB_CMDLINE_LINUX_DEFAULT=\"\\(.*\\)\";GRUB_CMDLINE_LINUX_DEFAULT=\"\\1 cryptroot=$ROOT_PARTITION cryptdm=root\";g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg 1>&2 | true

# Enabling all repositories mirrors
sed -i 's/^# \\?http/http/g' /etc/apk/repositories
apk update 1>&2 | true
apk upgrade 1>&2 | true

# Install helpers
install_pkg(){
	apk add \$@ 1>&2 | true
}
install_server(){
	install_pkg neovim doas lazygit neofetch git wget unzip openssh bash-completion nodejs npm python3 \
			py3-pip ripgrep mandoc htop gcc python3-dev musl-dev g++ bash curl cryptsetup mandoc \
			man-pages mandoc-apropos less less-doc

	# Replace sudo
	ln -s /usr/bin/doas /usr/bin/sudo

	# Enable the wheel group to use doas
	echo -e 'permit nopass :wheel\npermit nopass :wheel cmd poweroff\npermit nopass :wheel cmd reboot' > /etc/doas.conf

	# Replace default root shell
	sed -i 's,root:/root:/bin/ash,root:/root:/bin/bash,g' /etc/passwd

	# Adding user and setting password
	adduser -s /bin/bash $USERNAME << EOF
$USER_PASSWORD
$USER_PASSWORD
EOF

	# Installing the dotfiles
	echo \"#!/usr/bin/env bash

	# Exit immediately if a command exits with a non-zero exit status
	set -e

	# Add the user to the wheel group
	adduser $USERNAME wheel

	# Getting the dotfiles
	mkdir ~/git
	git clone https://github.com/saundersp/dotfiles.git ~/git/dotfiles

	# Enabling the dotfiles
	cd ~/git/dotfiles
	./auto.sh \$@
	sudo bash auto.sh \$@

	\" > /home/$USERNAME/install.sh
	chmod +x /home/$USERNAME/install.sh
	sudo -u $USERNAME /home/$USERNAME/install.sh $PACKAGES
	rm /home/$USERNAME/install.sh

	# Installing npm dependencies
	npm i -g neovim npm-check-updates

	# Installing pip dependencies
	pip install pynvim autopep8 flake8
}
install_ihm(){
	install_server
	install_pkg dmenu picom xinit xset feh alacritty xclip firefox vlc setxkbmap mesa-dri-swrast \
			i3wm-gaps polybar keepassxc

	# Setup repositories for xorg (input and xserver)
	setup-xorg-base 1>&2 | true

	# Add the user to the necessary groups
	adduser $USERNAME input
	adduser $USERNAME video

	# Installing the dotfiles
	echo \"#!/usr/bin/env bash

	# Exit immediately if a command exits with a non-zero exit status
	set -e

	# Enabling the dotfiles
	cd ~/git/dotfiles
	./auto.sh remove
	./auto.sh \$@
	sudo bash auto.sh remove
	sudo bash auto.sh \$@

	# Getting the wallpaper
	mkdir ~/Images
	cd ~/Images
	wget -q --show-progress https://www.pixelstalk.net/wp-content/uploads/2016/07/HD-Astronaut-Wallpaper.jpg
	\" > /home/$USERNAME/install.sh
	chmod +x /home/$USERNAME/install.sh
	sudo -u $USERNAME /home/$USERNAME/install.sh $PACKAGES
	rm /home/$USERNAME/install.sh

	# Getting the Hasklig font
	wget -q --show-progress https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Hasklig.zip
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
		install_pkg virtualbox-guest-additions xf86-video-vboxvideo
	;;
	laptop)
		install_ihm
		install_pkg os-prober brightnessctl intel-ucode wpa_supplicant ntfs-3g linux-firmware-nvidia pulseaudio \
					pulseaudio-bluez bluez pulsemixer
		# bumblebee-status-module-nvidia-prime xf86-video-intel nvidia nvidia-utils nvidia-settings

		# Allow vlc to use nvidia gpu
		echo -e '#\!/usr/bin/env bash\nprime-run vlc' > /usr/bin/pvlc
		chmod +x /usr/bin/pvlc

		# Allow user to use brightnessctl
		echo 'permit nopass :wheel cmd brightnessctl' >> /etc/doas.conf
	;;
esac

# Removing the nopass option in doas
sed -i '1s/nopass/persist/g' /etc/doas.conf

" > /mnt/root/install.sh
chmod +x /mnt/root/install.sh
chroot /mnt /root/install.sh

# Cleaning leftovers
rm /mnt/root/install.sh $@

reboot

