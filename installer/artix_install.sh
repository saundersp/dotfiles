#!/usr/bin/env bash

# Configuration (tweak to your liking)
USERNAME=saundersp
HOSTNAME=myarchbox
DISK=/dev/sda
DISK_LAST_SECTOR=
BOOT_PARTITION_INDEX=1
ROOT_PARTITION_INDEX=2
PARTITION_SEPARATOR=
FONT_PATH=/usr/share/fonts
PACKAGES=virtual
SWAP_SIZE=4G
CRYPTED_DISK_NAME=luks_root
GRUB_ID=GRUB
KEYMAP=fr
LOCALE=en_US
TIMEZONE=Europe/London
DISK_PASSWORD=
ROOT_PASSWORD=
USER_PASSWORD=
KERNEL=linux-zen
# Other options : linux linux-lts linux-zen linux-hardened
INIT_SYSTEM=openrc
# openrc  : nothing wrong detected
# runit   : nothing wrong detected
# s6      : shutdown signal is stuck
# suite66 : socket permission && shutdown signal is stuck
# dinit   : shutdown doesn't use the "now" argument && shutdown signal is stuck
# Other options : openrc runit s6 suite66 dinit

# Configuration checker
test -z $DISK_PASSWORD && echo 'Enter DISK password : ' && read -s DISK_PASSWORD
test -z $ROOT_PASSWORD && echo 'Enter ROOT password : ' && read -s ROOT_PASSWORD
test -z $USER_PASSWORD && echo 'Enter USER password : ' && read -s USER_PASSWORD

# List of disks
BOOT_PARTITION=$DISK$PARTITION_SEPARATOR$BOOT_PARTITION_INDEX
ROOT_PARTITION=$DISK$PARTITION_SEPARATOR$ROOT_PARTITION_INDEX

# Partition the disks
### GPT partition table
### Disk 1 - +256M - Bootable - UEFI Boot partition
### Disk 2 - Root partition
fdisk $DISK << EOF
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
echo -n $DISK_PASSWORD | cryptsetup luksFormat -v $ROOT_PARTITION
echo -n $DISK_PASSWORD | cryptsetup open $ROOT_PARTITION $CRYPTED_DISK_NAME

# Formatting the partitions
mkfs.vfat -n 'UEFI Boot' -F 32 $BOOT_PARTITION
mkfs.ext4 -L Root /dev/mapper/$CRYPTED_DISK_NAME

# Mounting the file systems
mount /dev/mapper/$CRYPTED_DISK_NAME /mnt
mkdir /mnt/boot
mount $BOOT_PARTITION /mnt/boot

# Creating and mounting the swap file
fallocate -l $SWAP_SIZE /mnt/swap
chmod 0600 /mnt/swap
chown root /mnt/swap
mkswap /mnt/swap
swapon /mnt/swap

# Enable pacman's parallels downloads
sed -i 's/^#Para/Para/g' /etc/pacman.conf

# Adding arch linux mirrors
pacman -Sy --noconfirm artix-archlinux-support
echo -e '\n# Arch\n[extra]\nInclude = /etc/pacman.d/mirrorlist-arch\n\n[community]\nInclude = /etc/pacman.d/mirrorlist-arch\n\n[multilib]\nInclude = /etc/pacman.d/mirrorlist-arch' >> /etc/pacman.conf

# Settings faster pacman arch mirrors
pacman -Sy --noconfirm reflector rsync
reflector -a 48 -c $(curl -q ifconfig.co/country-iso) -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist-arch

# Installing the init system
case $INIT_SYSTEM in
	openrc | runit | dinit | suite66) basestrap /mnt --needed base $KERNEL $INIT_SYSTEM elogind-$INIT_SYSTEM connman-$INIT_SYSTEM cryptsetup-$INIT_SYSTEM ;;
	s6) basestrap /mnt --needed base $KERNEL s6-base elogind-s6 connman-s6 cryptsetup-s6 ;;
	*) exit 1 ;;
esac

# Installing the common packages
basestrap /mnt --needed linux-firmware fakeroot make gcc pkgconf neovim opendoas grub efibootmgr lazygit neofetch which dmenu picom i3-gaps xorg-xinit xorg-server \
				xorg-xset feh alacritty git wget unzip keepass openssh xclip firefox bash-completion reflector rsync nodejs npm python python-pip ripgrep vlc man \
				sed htop

# Installing the platform specific packages
case $PACKAGES in
	virtual) basestrap /mnt --needed virtualbox-guest-utils ;;
	laptop)
		basestrap /mnt --needed os-prober xf86-video-intel nvidia nvidia-utils nvidia-prime nvidia-settings ntfs-3g pulseaudio pulsemixer \
					pulseaudio-bluetooth patch bluez-utils intel-ucode wpa_supplicant bluez-$INIT_SYSTEM
		echo -e '#\!/usr/bin/env bash\nprime-run vlc' >> /mnt/usr/bin/pvlc
		chmod +x /mnt/usr/bin/pvlc
	;;
	*) exit 1 ;;
esac

# Copying optimized mirrors
cp /etc/pacman.conf /mnt/etc/pacman.conf
cp /etc/pacman.d/mirrorlist-arch /mnt/etc/pacman.d/mirrorlist-arch

# Generating the mounting points
fstabgen -U /mnt >> /mnt/etc/fstab

echo "#!/usr/bin/env bash

# Installing npm dependencies
npm i -g neovim npm-check-updates

# Installing pip dependencies
pip install pynvim autopep8 flake8

# Getting the Hasklig font
wget -q --show-progress https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Hasklig.zip
mkdir $FONT_PATH/Hasklig
unzip -q Hasklig.zip -d $FONT_PATH/Hasklig
rm Hasklig.zip

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
sed -i 's/modconf block filesystems /keyboard keymap modconf block encrypt filesystems /g' /etc/mkinitcpio.conf
mkinitcpio -p $KERNEL

# Installing GRUB bootloader
grub-install --target x86_64-efi --efi-directory /boot --bootloader-id $GRUB_ID --recheck

# Prepare boot loader for LUKS
sed -i \"s,X=\\\"\\\",X=\\\"cryptdevice=UUID=\$(blkid $ROOT_PARTITION | cut -d \\\" -f 2):$CRYPTED_DISK_NAME root=/dev/mapper/$CRYPTED_DISK_NAME\\\",g\" /etc/default/grub

# Enable os-prober if laptop
test $PACKAGES == 'laptop' && echo GRUB_DISABLE_OS_PROBER=0 >> /etc/default/grub

# Creating the GRUB configuration file
grub-mkconfig -o /boot/grub/grub.cfg

# Configuring the connmand per init system
case $INIT_SYSTEM in
	openrc)
		# Adding connman daemon at startup
		rc-update add connmand

		# Adding the keyboard layout to OpenRC
		sed -i 's/\"us\"/\"$KEYMAP\"/g' /etc/conf.d/keymaps

		# Adding hostname to OpenRC
		sed -i 's/localhost/$HOSTNAME/g' /etc/conf.d/hostname
	;;

	runit)
		# Adding connman daemon at startup
		ln -s /etc/runit/sv/connmand /etc/runit/runsvdir/default
	;;

	s6)
		# Adding connman daemon at startup
		s6-rc-bundle-update -c /etc/s6/rc/compiled add default connmand
	;;

	suite66)
		# Creating the config file
		66-env -t boot boot@system

		# Getting the config file to setup
		CONF_FILE=/etc/suite66/conf/boot@system/\$(ls /etc/suite66/conf/boot@system | grep -v version)/boot@system

		# Adding the keyboard layout to Suite66
		sed -i 's/!us/!$KEYMAP/g' \$CONF_FILE

		# Adding hostname to Suite66
		sed -i 's/artixlinux/$HOSTNAME/g' \$CONF_FILE

		# Enabling swap in Suite66
		sed -i 's/SWAP=!no/SWAP=!yes/g' \$CONF_FILE

		# Enabling encrypted devices in Suite66
		sed -i 's/CRYPTTAB=!no/CRYPTTAB=!yes/g' \$CONF_FILE

		# Apply all changes
		66-enable -t boot -F boot@system

		# Adding connman daemon at startup
		66-enable -t boot connmand
	;;

	dinit)
		# Adding connman daemon at startup
		ln -s /etc/dinit.d/connmand /etc/dinit.d/boot.d/
	;;
esac

# Enabling all threads during makepkg
sed -i \"s/^#MAKEFLAGS=\\\"-j2\\\"/MAKEFLAGS=\\\"-j\$(nproc)\\\"/g\" /etc/makepkg.conf
sed -i \"s/^COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -z - --threads=\$(nproc))/g\" /etc/makepkg.conf
" > /mnt/root/install.sh
chmod +x /mnt/root/install.sh
artix-chroot /mnt /root/install.sh

echo "#!/usr/bin/env bash

# Getting the dotfiles
mkdir ~/git
git clone https://github.com/saundersp/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles
./auto.sh

# Getting the wallpaper
mkdir ~/Images
curl https://www.pixelstalk.net/wp-content/uploads/2016/07/HD-Astronaut-Wallpaper.jpg > ~/Images/HD-Astronaut-Wallpaper.jpg

# Installing the AUR packages
aur_install(){
	git clone https://aur.archlinux.org/\$1.git ~/aur/\$1
	cd ~/aur/\$1
	makepkg -sri --noconfirm
}

aur_install polybar
if [ $PACKAGES == 'laptop' ]; then
	aur_install davmail
	gpg --auto-key-locate nodefault,wkd --locate-keys torbrowser@torproject.org
	aur_install tor-browser
	aur_install font-manager
fi
" > /mnt/home/$USERNAME/install.sh
chmod +x /mnt/home/$USERNAME/install.sh
artix-chroot /mnt /usr/bin/runuser -u $USERNAME /home/$USERNAME/install.sh

# Getting dotfiles as root
echo -e "#!/usr/bin/env bash\ncd /home/$USERNAME/git/dotfiles\n./auto.sh" > /mnt/root/install.sh
artix-chroot /mnt /root/install.sh

# Cleaning leftovers
rm /mnt/root/install.sh /mnt/home/$USERNAME/install.sh

# Removing the nopass option in doas
sed -i 's/nopass/persist/g' /mnt/etc/doas.conf

# Allow user to shutdown and reboot
echo -e 'permit nopass :wheel cmd shutdown\npermit nopass :wheel cmd reboot' >> /mnt/etc/doas.conf

# Allow user to use brightnessctl (laptop only)
test $PACKAGES == 'laptop' && echo 'permit nopass :wheel cmd brightnessctl' >> /mnt/etc/doas.conf

# Unmounting the partitions
umount -R /mnt

reboot

