#!/usr/bin/env bash

# Pre-setup steps :
# login as root:voidlinux
# loadkeys fr
# If WiFi : wpa_supplicant https://docs.voidlinux.org/config/network/wpa_supplicant.html
# xbps-install -Syu xbps curl

# Configuration (tweak to your liking)
USERNAME=saundersp
HOSTNAME=myvoidbox
DISK=/dev/sda
DISK_LAST_SECTOR=
BOOT_PARTITION_INDEX=1
ROOT_PARTITION_INDEX=2
PARTITION_SEPARATOR=
PACKAGES=virtual
# Other options : virtual laptop server minimal
SWAP_SIZE=4G
CRYPTED_DISK_NAME=luks_root
GRUB_ID=GRUB
KEYMAP=fr
LOCALE=en_US
TIMEZONE=Europe/London
DISK_PASSWORD=
ROOT_PASSWORD=
USER_PASSWORD=
MIRROR=https://repo-default.voidlinux.org/current
# Other options at https://docs.voidlinux.org/xbps/repositories/mirrors/index.html
ARCH=x86_64
# Other options : x86_64 x86_64-musl i686

# Configuration checker
test -z "$DISK_PASSWORD" && echo 'Enter DISK password : ' && read -r -s DISK_PASSWORD
test -z "$ROOT_PASSWORD" && echo 'Enter ROOT password : ' && read -r -s ROOT_PASSWORD
test -z "$USER_PASSWORD" && echo 'Enter USER password : ' && read -r -s USER_PASSWORD

# Exit immediately if a command exits with a non-zero exit status
set -e

# List of disks
BOOT_PARTITION=$DISK$PARTITION_SEPARATOR$BOOT_PARTITION_INDEX
ROOT_PARTITION=$DISK$PARTITION_SEPARATOR$ROOT_PARTITION_INDEX

# Partition the disks
### GPT partition table
### Disk 1 - +256M - Bootable - UEFI Boot partition
### Disk 2 - Root partition
fdisk "$DISK" << EOF
g
n
$BOOT_PARTITION_INDEX

+256M
t
uefi
n
$ROOT_PARTITION_INDEX


$DISK_LAST_SECTOR
w
EOF

# Encrypting the root partition
echo -n "$DISK_PASSWORD" | cryptsetup luksFormat -v "$ROOT_PARTITION"
echo -n "$DISK_PASSWORD" | cryptsetup open "$ROOT_PARTITION" "$CRYPTED_DISK_NAME"

# Formatting the partitions
mkfs.vfat -n 'UEFI Boot' -F 32 "$BOOT_PARTITION"
mkfs.ext4 -L Root /dev/mapper/"$CRYPTED_DISK_NAME"

# Mounting the file systems
mount /dev/mapper/"$CRYPTED_DISK_NAME" /mnt
mkdir -p /mnt/boot
mount "$BOOT_PARTITION" /mnt/boot

# Creating and mounting the swap file
fallocate -l "$SWAP_SIZE" /mnt/swap
chmod 0600 /mnt/swap
chown root /mnt/swap
mkswap /mnt/swap
swapon /mnt/swap

# install shortcut
install_pkg(){
	env XBPS_ARCH=$ARCH xbps-install -Sy -R "$MIRROR" -r /mnt $@
}

install_pkg base-system opendoas grub-x86_64-efi efibootmgr cryptsetup which man-db sed connman dash << EOF

EOF

install_server(){
	install_pkg neovim lazygit lazydocker git wget unzip openssh bash-completion nodejs python3 python3-pip ripgrep btop ranger tmux \
		docker dos2unix fd highlight gcc gdb xtools docker-compose progress python3-neovim ncdu cmake make Vulkan-Headers
}
install_ihm(){
	install_server
	install_pkg picom i3-gaps i3lock xorg-minimal xset setxkbmap xrandr xrdb feh vlc firefox polybar calibre filezilla zathura \
		zathura-pdf-mupdf libX11-devel libXft-devel libXinerama-devel pkg-config harfbuzz-devel patch wireguard ImageMagick \
		openssl-devel tbb-devel libxcb-devel xcb-util-image-devel libopencv-devel libvips-devel libsixel-devel chafa-devel
}

# Installing the platform specific packages
case $PACKAGES in
	virtual)
		install_ihm
		install_pkg xf86-video-vmware virtualbox-ose-guest
	;;
	server)	install_server ;;
	minimal) ;;
	laptop)
		install_ihm
		install_pkg os-prober xf86-video-intel ntfs-3g pulseaudio pulsemixer wpa_supplicant xbacklight
		env XBPS_ARCH=$ARCH xbps-install -Sy -R "$MIRROR"/nonfree -r /mnt nvidia intel-ucode
		echo -e '#\!/usr/bin/env bash\nprime-run vlc' >> /mnt/usr/bin/pvlc
		chmod +x /mnt/usr/bin/pvlc
	;;
esac

# Mouting pseudo-filesystems
mount -R /sys /mnt/sys
mount --make-rslave /mnt/sys
mount -R /dev /mnt/dev
mount --make-rslave /mnt/dev
mount -R /proc /mnt/proc
mount --make-rslave /mnt/proc

# Copying the DNS configuration
cp /etc/resolv.conf /mnt/etc

echo "#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero exit status
set -e

# Use dash instead of bash
ln -sf /bin/dash /bin/sh

# Removing unused programs
rm -rf \$(find / -name *sudo*) /sbin/vi

if [ '$PACKAGES' != 'minimal' ]; then
	# Installing npm dependencies
	npm i -g neovim npm-check-updates
fi

if [[ '$PACKAGES' == 'laptop' || '$PACKAGES' == 'virtual' ]]; then
	# Getting the Hasklig font
	LATEST_TAG=\$(curl https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep tag_name | cut -d \\\" -f 4)
	wget -q --show-progress https://github.com/ryanoasis/nerd-fonts/releases/download/\"\$LATEST_TAG\"/Hasklig.zip
	mkdir -p /usr/share/fonts/Hasklig
	unzip -q Hasklig.zip -d /usr/share/fonts/Hasklig
	echo \$LATEST_TAG > /usr/share/fonts/Hasklig/VERSION
	rm Hasklig.zip
fi

# Set the LANG variable
echo LANG=$LOCALE.UTF-8 > /etc/locale.conf

# Setting the hostname
echo $HOSTNAME > /etc/hostname

# Configuration options
echo '
HARDWARECLOCK=\"UTC\"
TIMEZONE=\"$TIMEZONE\"
KEYMAP=\"$KEYMAP\"
' > /etc/rc.conf

# Configuring the locales
sed -i 's/#$LOCALE/$LOCALE/g' /etc/default/libc-locales

# Setting a root password
passwd << EOF
$ROOT_PASSWORD
$ROOT_PASSWORD
EOF

# Changing the default bash of root
chsh -s /bin/bash

# Adding user and creating home directory
useradd -m -G wheel $USERNAME

# Setting a user password
passwd $USERNAME << EOF
$USER_PASSWORD
$USER_PASSWORD
EOF

# Replace sudo
ln -s /usr/bin/doas /usr/bin/sudo

# Enable the wheel group to use doas and allow users to poweroff and reboot
echo -e 'permit nopass :wheel\npermit nopass :wheel cmd poweroff\npermit nopass :wheel cmd reboot' >> /etc/doas.conf

# Setting up the fstab auto mouting
echo \"
UUID=\$(blkid -s UUID -o value $BOOT_PARTITION) /boot vfat defaults,noatime 0 2
UUID=\$(blkid -s UUID -o value /dev/mapper/$CRYPTED_DISK_NAME) / ext4 noatime 0 1
/swap none swap defaults 0 0
tmpfs /tmp tmpfs defaults,nosuid,nodev 0 0
\" >> /etc/fstab

# Prepare boot loader for LUKS
echo -e \"GRUB_CMDLINE_LINUX=\\\"rd.luks.uuid=\$(blkid -s UUID -o value $ROOT_PARTITION) root=/dev/mapper/luks-\$(blkid -s UUID -o value $ROOT_PARTITION)\\\"\" >> /etc/default/grub
sed -i 's/loglevel=4\"/loglevel=4 rd.vconsole.keymap=$KEYMAP\"/g' /etc/default/grub

# Enable os-prober if laptop
if [ '$PACKAGES' == 'laptop' ]; then
	echo GRUB_DISABLE_OS_PROBER=false >> /etc/default/grub
	os-prober
fi

# Installing GRUB bootloader
grub-install --target x86_64-efi --efi-directory /boot --bootloader-id $GRUB_ID --recheck

# Creating the GRUB configuration file
grub-mkconfig -o /boot/grub/grub.cfg

# Ensure all installed packages are configured properly
xbps-reconfigure -fa \$(xbps-query -s 'linux\d*' | cut -f 2 -d ' ' | cut -f 1 -d -)

# Enabling internet at startup
ln -s /etc/sv/connmand /etc/runit/runsvdir/default/
ln -s /etc/sv/dhcpcd /etc/runit/runsvdir/default/

# Creating custom packages source directory
mkdir /usr/local/src

if [ '$PACKAGES' == 'laptop' ] || [ '$PACKAGES' == 'virtual' ] || [ '$PACKAGES' == 'server' ]; then
	# Installing lazynpm from source
	cd /usr/local/src
	git clone https://github.com/jesseduffield/lazynpm.git
	cd lazynpm
	go install -buildvcs=false
	mv /root/go/bin/lazynpm /usr/local/bin/lazynpm

	# Installing fastfetch from source
	cd /usr/local/src
	git clone https://github.com/fastfetch-cli/fastfetch.git
	cd fastfetch
	cmake -B build
	cmake --build build --target fastfetch --target flashfetch -j \$(nproc)
	mv /usr/local/src/fastfetch/build/fastfetch /usr/local/bin/fastfetch
	rm -r build
fi

if [ '$PACKAGES' == 'laptop' ] || [ '$PACKAGES' == 'virtual' ]; then
	# Installing ueberzugpp from source
	cd /usr/local/src
	git clone https://github.com/jstkdng/ueberzugpp.git
	cd ueberzugpp
	cmake -DCMAKE_BUILD_TYPE=Release build
	cmake --build build -j \$(nproc)
	mv /usr/local/src/ueberzugpp/build/ueberzugpp /usr/local/bin/ueberzugpp
	mv /usr/local/src/ueberzugpp/build/ueberzug /usr/local/bin/ueberzug
	rm -r build
fi
" > /mnt/install.sh
chmod +x /mnt/install.sh
chroot /mnt /install.sh

echo "#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero exit status
set -e

if [ '$PACKAGES' != 'minimal' ]; then
	# Getting the dotfiles
	mkdir ~/git
	git clone https://github.com/saundersp/dotfiles.git ~/git/dotfiles
fi

case $PACKAGES in
	minimal) ;;
	server)
		# Enabling the dotfiles
		cd ~/git/dotfiles
		./auto.sh server
		sudo bash auto.sh server
	;;
	virtual|laptop)
		# Enabling the dotfiles
		cd ~/git/dotfiles
		./auto.sh install
		sudo bash auto.sh install

		# Getting the wallpaper
		mkdir ~/Images
		cd ~/Images
		wget -q --show-progress https://www.pixelstalk.net/wp-content/uploads/2016/07/HD-Astronaut-Wallpaper.jpg
		convert -crop '2560x1440!+0+70' HD-Astronaut-Wallpaper.jpg WanderingAstronaut.png
		rm HD-Astronaut-Wallpaper.jpg
		echo -e '#!/bin/sh\nfeh --bg-fill ~/Images/WanderingAstronaut.png' > ~/.fehbg
		chmod +x ~/.fehbg
	;;
esac

# Removing the nopass option in doas
sudo sed -i '1s/nopass/persist/g' /etc/doas.conf

" > /mnt/home/"$USERNAME"/install.sh
chmod +x /mnt/home/"$USERNAME"/install.sh
chroot /mnt /usr/bin/runuser -u "$USERNAME" /home/"$USERNAME"/install.sh

# Cleaning leftovers
rm /mnt/install.sh /mnt/home/"$USERNAME"/install.sh /root/"$0"

reboot

