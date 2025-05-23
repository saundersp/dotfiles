#!/usr/bin/env bash

# Pre-setup steps :
# loadkeys $KEYMAP
# If WiFi : iwctl

# Configuration (tweak to your liking)
USERNAME=saundersp
HOSTNAME=myarchbox
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
KEYMAP=us
LOCALE=en_US
TIMEZONE=Europe/London
DISK_PASSWORD=
ROOT_PASSWORD=
USER_PASSWORD=
KERNEL=linux-zen
# Other options : linux linux-lts linux-zen linux-hardened

# BIOS not supported
test ! -d /sys/firmware/efi/efivars && echo 'Missing UEFI vars, exiting...' && exit 1

# Configuration checker
test -z "$DISK_PASSWORD" && echo 'Enter DISK password : ' && read -r -s DISK_PASSWORD
test -z "$ROOT_PASSWORD" && echo 'Enter ROOT password : ' && read -r -s ROOT_PASSWORD
test -z "$USER_PASSWORD" && echo 'Enter USER password : ' && read -r -s USER_PASSWORD

# Exit immediately if a command exits with a non-zero exit status
set -e

# Updating the system clock
timedatectl set-ntp true

# List of disks
BOOT_PARTITION="$DISK$PARTITION_SEPARATOR$BOOT_PARTITION_INDEX"
ROOT_PARTITION="$DISK$PARTITION_SEPARATOR$ROOT_PARTITION_INDEX"

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
mount --mkdir "$BOOT_PARTITION" /mnt/boot

# Creating and mounting the swap file
fallocate -l "$SWAP_SIZE" /mnt/swap
chmod 0600 /mnt/swap
chown root /mnt/swap
mkswap /mnt/swap
swapon /mnt/swap

# Enable pacman's parallels downloads and colours
sed -i 's/^#Color/Color/g;s/^#Para/Para/g' /etc/pacman.conf

# Settings faster pacman mirrors
reflector -a 48 -c "$(curl -q ifconfig.io/country_code)" -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist

# Install helpers
install_pkg(){
	pacstrap /mnt --needed $@
}
install_server(){
	install_pkg neovim lazygit fastfetch git wget unzip openssh bash-completion reflector rsync nodejs npm python python-pip ripgrep \
		btop yazi fd fakeroot make gcc pkgconf tmux docker docker-compose dos2unix gdb highlight progress python-pynvim debugedit \
		tree-sitter-cli ncdu
}
install_ihm(){
	install_server
	install_pkg picom i3-wm xorg-xinit xorg-server xorg-xset feh xclip mpv polybar ueberzug patch calibre filezilla i3lock zathura \
		zathura-pdf-mupdf imagemagick tor rofi otf-hasklig-nerd
}

# Installing the minimal packages
install_pkg base "$KERNEL" linux-firmware opendoas grub efibootmgr which man sed cryptsetup connman dash

# Installing the platform specific packages
case $PACKAGES in
	virtual)
		install_ihm
		install_pkg virtualbox-guest-utils
	;;
	server) install_server ;;
	minimal) ;;
	laptop)
		install_ihm
		install_pkg os-prober xf86-video-intel nvidia-utils nvidia-prime nvidia-settings ntfs-3g pulseaudio pulsemixer pulseaudio-bluetooth \
			patch bluez-utils intel-ucode wpa_supplicant brightnessctl bluez wireguard-tools
		case $KERNEL in
			linux) install_pkg nvidia ;;
			linux-lts) install_pkg nvidia-lts ;;
			*) install_pkg nvidia-dkms "$KERNEL"-headers ;;
		esac
	;;
esac

# Copying optimized mirrors
cp /etc/pacman.conf /mnt/etc/pacman.conf
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

# Generating the mounting points
genfstab -U /mnt >> /mnt/etc/fstab

echo "#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero exit status
set -e

# Use dash instead of bash as default shell
ln -sf /bin/dash /bin/sh

# Removing unused programs
rm -rf \$(find / -name *sudo*) /sbin/vi

if [ '$PACKAGES' != 'minimal' ]; then
	# Installing npm dependencies
	npm i -g npm-check-updates
fi

# Set the time zone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime

# Setting hardware clock
hwclock --systohc

# Edit the file /etc/locale.gen uncomment UTF-8 and ISO
sed -i 's/#$LOCALE/$LOCALE/g' /etc/locale.gen
locale-gen

# Set the LANG variable
echo LANG=$LOCALE.UTF-8 > /etc/locale.conf

# Setting the keyboard layout
echo KEYMAP=$KEYMAP > /etc/vconsole.conf

# Setting the hostname
echo $HOSTNAME > /etc/hostname

# Add networking entities to /etc/hosts
echo '
127.0.0.1    localhost
::1          localhost
127.0.1.1    $HOSTNAME.localdomain $HOSTNAME
' >> /etc/hosts

# Setting a root password
passwd << EOF
$ROOT_PASSWORD
$ROOT_PASSWORD
EOF

# Adding user and creating home directory
useradd -m -G wheel $USERNAME

# Setting a user password
passwd $USERNAME << EOF
$USER_PASSWORD
$USER_PASSWORD
EOF

# Enable the wheel group to use doas
echo 'permit nopass :wheel' > /etc/doas.conf

# Replace sudo
ln -s /usr/bin/doas /usr/bin/sudo

# Initialize Initiramfs
sed -i 's/block filesystems fsck/block encrypt filesystems fsck/g' /etc/mkinitcpio.conf
mkinitcpio -p $KERNEL

# Prepare boot loader for LUKS
sed -i \"s,X=\\\"\\\",X=\\\"cryptdevice=UUID=\$(blkid -s UUID -o value $ROOT_PARTITION):$CRYPTED_DISK_NAME root=/dev/mapper/$CRYPTED_DISK_NAME\\\",g\" /etc/default/grub

# Enable os-prober if laptop
if [ '$PACKAGES' == 'laptop' ]; then
	echo GRUB_DISABLE_OS_PROBER=false >> /etc/default/grub
	os-prober
fi

# Installing GRUB bootloader
grub-install --target x86_64-efi --efi-directory /boot --bootloader-id $GRUB_ID --recheck

# Creating the GRUB configuration file
grub-mkconfig -o /boot/grub/grub.cfg

# Enabling networking
systemctl enable connman

# Enabling all threads during makepkg
sed -i \"s/^#MAKEFLAGS=\\\"-j2\\\"/MAKEFLAGS=\\\"-j\$(nproc)\\\"/g\" /etc/makepkg.conf
sed -i \"s/^COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -z - --threads=\$(nproc))/g\" /etc/makepkg.conf
# Fix AUR install to support doas instead of sudo
sed -i 's/#PACMAN_AUTH=()/PACMAN_AUTH=(doas)/' /etc/makepkg.conf
" > /mnt/root/install.sh
chmod +x /mnt/root/install.sh
arch-chroot /mnt /root/install.sh

echo "#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero exit status
set -e

if [ '$PACKAGES' != 'minimal' ]; then
	# Getting the dotfiles
	mkdir ~/git
	git clone https://github.com/saundersp/dotfiles.git ~/git/dotfiles
fi

# Allow user to poweroff and reboot
echo -e 'permit nopass :wheel cmd poweroff\npermit nopass :wheel cmd reboot' | sudo tee -a /etc/doas.conf

# Installing the AUR packages
aur_install(){
	git clone https://aur.archlinux.org/\$1.git ~/.aur/\$1
	cd ~/.aur/\$1
	local GPG_KEY=\$(cat PKGBUILD | grep validpgpkeys | cut -d \"'\" -f 2)
	test ! -z \$GPG_KEY && gpg --recv-key \$GPG_KEY
	makepkg -sri --noconfirm
}

case $PACKAGES in
	minimal) ;;
	server)
		# Removing bash profile that blocks default .profile
		rm -v ~/.bash_profile ~/.bash_logout

		# Enabling the dotfiles
		cd ~/git/dotfiles
		./auto.sh server
		sudo bash auto.sh server

		aur_install lazydocker
	;;
	virtual|laptop)
		# Removing bash profile that blocks default .profile
		rm -v ~/.bash_profile ~/.bash_logout

		# Enabling the dotfiles
		cd ~/git/dotfiles
		./auto.sh install
		sudo bash auto.sh install

		# Getting the wallpaper
		mkdir ~/Images
		cd ~/Images
		wget -q --show-progress https://www.pixelstalk.net/wp-content/uploads/2016/07/HD-Astronaut-Wallpaper.jpg
		magick convert -crop '2560x1440!+0+70' HD-Astronaut-Wallpaper.jpg WanderingAstronaut.png
		rm HD-Astronaut-Wallpaper.jpg
		echo -e '#!/bin/sh\nfeh --bg-fill ~/Images/WanderingAstronaut.png' > ~/.fehbg
		chmod +x ~/.fehbg

		aur_install lazydocker
		rm -rfv ~/go
		aur_install librewolf-bin
		curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | gpg --import -
		aur_install spotify
	;;
esac

# Removing the nopass option in doas
sudo sed -i '1s/nopass/persist/g' /etc/doas.conf

" > /mnt/home/"$USERNAME"/install.sh
chmod +x /mnt/home/"$USERNAME"/install.sh
arch-chroot /mnt /usr/bin/runuser -u "$USERNAME" /home/"$USERNAME"/install.sh

# Cleaning leftovers
rm /mnt/root/install.sh /mnt/home/"$USERNAME"/install.sh "$0"

reboot

