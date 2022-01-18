#!/usr/bin/env bash

# Pre-setup steps :
# select $KEYMAP
# If WiFi : wpa_supplicant

# Configuration (tweak to your liking)
USERNAME=saundersp
HOSTNAME=mygentoobox
DISK=/dev/sda
DISK_LAST_SECTOR=
BOOT_PARTITION_INDEX=1
ROOT_PARTITION_INDEX=2
PARTITION_SEPARATOR=
FONT_PATH=/usr/share/fonts
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
STAGE_TYPE=openrc
# Others options :
# - hardened-nomultilib-openrc
# - hardened-nomultilib-selinux-openrc
# - hardened-openrc
# - hardened-selinux-openrc
# - nomultilib-openrc

test -z $DISK_PASSWORD && echo 'Enter DISK password : ' && read -s DISK_PASSWORD
test -z $ROOT_PASSWORD && echo 'Enter ROOT password : ' && read -s ROOT_PASSWORD
test -z $USER_PASSWORD && echo 'Enter USER password : ' && read -s USER_PASSWORD

# Exit immediately if a command exits with a non-zero exit status
set -e

# List of disks
BOOT_PARTITION=$DISK$PARTITION_SEPARATOR$BOOT_PARTITION_INDEX
ROOT_PARTITION=$DISK$PARTITION_SEPARATOR$ROOT_PARTITION_INDEX

# Partition the disks
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
mount /dev/mapper/$CRYPTED_DISK_NAME /mnt/gentoo
mkdir -p /mnt/gentoo/boot
mount $BOOT_PARTITION /mnt/gentoo/boot

# Creating and mounting the swap file
fallocate -l $SWAP_SIZE /mnt/gentoo/swap
chmod 0600 /mnt/gentoo/swap
chown root /mnt/gentoo/swap
mkswap /mnt/gentoo/swap
swapon /mnt/gentoo/swap

cd /mnt/gentoo

# links gentoo.org/downloads
STAGE_NAME=$(curl -s http://distfiles.gentoo.org/releases/amd64/autobuilds/latest-stage3-amd64-$STAGE_TYPE.txt | grep -v '^#' | cut -d' ' -f 1)
wget http://distfiles.gentoo.org/releases/amd64/autobuilds/$STAGE_NAME
STAGE_FILENAME=$(basename $STAGE_NAME)
tar xpf $STAGE_FILENAME --xattrs-include='*.*' --numeric-owner

sed -i 's/COMMON_FLAGS="/COMMON_FLAGS="-march=native /g' /mnt/gentoo/etc/portage/make.conf
echo -e "MAKEOPTS=\"-j$(nproc)\"\nACCEPT_LICENSE=\"*\"" >> /mnt/gentoo/etc/portage/make.conf

mirrorselect -a -s 20 -o >> /mnt/gentoo/etc/portage/make.conf

mkdir -p /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf

cp -L /etc/resolv.conf /mnt/gentoo/etc/

mount -t proc /proc /mnt/gentoo/proc
mount -R /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount -R /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount -B /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run

echo "#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero exit status
set -e

source /etc/profile

# Updating the Gentoo ebuild repository
emerge --quiet --sync

# Choosing the default minimal profile
eselect profile set 1

# Apply the default USE flags to the @world set
emerge --quiet --update --deep --newuse @world

# Configuring the USE flags
# Get all enabled flags : portageq envvar USE | xargs -n1
# Note : use 'less /var/db/repos/gentoo/profiles/use.desc' to get a description of each variables

# Removing the existing package.use
rm -rf /etc/portage/package.use /etc/portage/package.accept_keywords /etc/portage/package.mask
touch /etc/portage/package.use /etc/portage/package.accept_keywords /etc/portage/package.mask

case $PACKAGES in
	minimal)
		# Global flags
		echo 'USE=\"elogind\"' >> /etc/portage/make.conf
	;;
	server)
		# Global flags
		echo 'USE=\"X bash-completion elogind python\"' >> /etc/portage/make.conf
		# Package accept_keywords
		echo 'app-editors/neovim ~amd64' >> /etc/portage/package.accept_keywords
	;;
	virtual)
		# Global flags
		echo 'USE=\"X bash-completion elogind python\"' >> /etc/portage/make.conf
		# Local flags
		echo 'x11-misc/polybar i3wm' > /etc/portage/package.use
		# Package accept_keywords
		echo 'app-editors/neovim ~amd64' >> /etc/portage/package.accept_keywords
	;;
	laptop)
		# Global flags
		echo 'USE=\"X bash-completion connman elogind pulseaudio python\"' >> /etc/portage/make.conf
		# Local flags
		echo 'x11-misc/polybar i3wm' > /etc/portage/package.use
		# Package accept_keywords
		echo 'app-editors/neovim ~amd64' >> /etc/portage/package.accept_keywords
	;;
	*) exit 1 ;;
esac

# Setting the timezone
echo $TIMEZONE > /etc/timezone
emerge --quiet --config sys-libs/timezone-data

# Setting the locale
echo -e '$LOCALE.UTF-8 UTF-8\n$LOCALE ISO-8859-1' >> /etc/locale.gen
locale-gen
eselect locale set \$(eselect locale list | grep $LOCALE.utf8 | grep -oP '\[\K\d*(?=\])')
env-update
source /etc/profile

# Installing cryptsetup
emerge --quiet sys-fs/cryptsetup
rc-update add dmcrypt boot

# Compilation and installation of the kernel
#emerge --quiet sys-kernel/gentoo-sources
#eselect kernel set 1
#cd /usr/src/linux
#make menuconfig
#make
#make modules_install
#make install
#emerge --quiet sys-apps/pciutils

# Building the kernel and initramfs
emerge --quiet sys-kernel/genkernel
genkernel --luks all

# Installing the firmware
emerge --quiet sys-kernel/linux-firmware

# Setting up the fstab auto mouting
echo \"
UUID=\$(blkid -s UUID -o value $BOOT_PARTITION) /boot vfat defaults,noatime 0 2
UUID=\$(blkid -s UUID -o value /dev/mapper/$CRYPTED_DISK_NAME) / ext4 noatime 0 1
/swap none swap defaults 0 0
\" >> /etc/fstab

# Setting the hostname
sed -i 's/localhost/$HOSTNAME/g' /etc/conf.d/hostname

# Setting network
emerge --quiet --noreplace net-misc/netifrc
emerge --quiet net-misc/dhcpcd
rc-update add dhcpcd default

# Setting a root password
passwd << EOF
$ROOT_PASSWORD
$ROOT_PASSWORD
EOF

# Adding user and creating home directory
useradd -m -G users,wheel,video,audio -s /bin/bash $USERNAME

# Setting a user password
passwd $USERNAME << EOF
$USER_PASSWORD
$USER_PASSWORD
EOF

# Installing and setting up doas
emerge --quiet app-admin/doas
echo 'permit nopass :wheel' > /etc/doas.conf

# Replace sudo
ln -s /usr/bin/doas /usr/bin/sudo

# Setup keyboard for OpenRC
sed -i 's/\"us\"/\"$KEYMAP\"/g' /etc/conf.d/keymaps

# Setup logging system
emerge --quiet app-admin/sysklogd
rc-update add sysklogd default

# Getting the filesystems packages
emerge --quiet sys-fs/e2fsprogs sys-fs/dosfstools

# Installing the bootloader
echo 'GRUB_PLATFORMS=\"efi-64\"' >> /etc/portage/make.conf
emerge --quiet sys-boot/grub

# Prepare boot loader for LUKS
sed -i \"s,^#GRUB_CMDLINE_LINUX=\\\"\\\",GRUB_CMDLINE_LINUX=\\\"crypt_root=UUID=\$(blkid -s UUID -o value $ROOT_PARTITION) root=/dev/mapper/root keymap=$KEYMAP\\\",g\" /etc/default/grub

# Enable os-prober if laptop
if [ '$PACKAGES' == 'laptop' ]; then
	echo GRUB_DISABLE_OS_PROBER=0 >> /etc/default/grub
	emerge --quiet sys-boot/os-prober
	os-prober
fi

# Installing GRUB bootloader
grub-install --target x86_64-efi --efi-directory /boot --removable --bootloader-id $GRUB --recheck

# Creating the GRUB configuration file
grub-mkconfig -o /boot/grub/grub.cfg

# Installing minimal packages
emerge --quiet sys-auth/elogind sys-apps/which

install_server(){
	emerge --quiet app-misc/neofetch app-editors/neovim sys-apps/which dev-vcs/git net-misc/wget app-arch/unzip app-shells/bash-completion net-libs/nodejs \
					dev-lang/python sys-apps/ripgrep sys-apps/man-db dev-python/pip
}
install_ihm(){
	emerge --quiet x11-misc/dmenu x11-misc/picom x11-wm/i3-gaps x11-apps/xinit x11-base/xorg-server x11-apps/xset media-gfx/feh x11-terms/alacritty \
					x11-misc/polybar x11-apps/xrandr x11-misc/xclip x11-apps/setxkbmap
}

case $PACKAGES in
	virtual)
		install_ihm
		#emerge --quiet app-emulation/virtualbox-guest-additions
	;&
	server) install_server ;&
	minimal) ;;
	laptop)
		install_minimal
		install_server
		install_ihm
		emerge --quiet net-wireless/iw net-wireless/wpa_supplicant
	;;
	*) exit 1 ;;
esac

# Start elogind service at boot
rc-update add elogind boot

if [ '$PACKAGES' != 'minimal' ]; then
	# Installing npm dependencies
	npm i -g neovim npm-check-updates

	# Installing pip dependencies
	pip install --user pynvim autopep8 flake8
	# TODO : Fix install as root && softlink to /usr/bin
fi

if [[ '$PACKAGES' == 'laptop' || '$PACKAGES' == 'virtual' ]]; then
	# Getting the Hasklig font
	wget -q --show-progress https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Hasklig.zip
	mkdir $FONT_PATH/Hasklig
	unzip -q Hasklig.zip -d $FONT_PATH/Hasklig
	rm Hasklig.zip
fi

" > /mnt/gentoo/install.sh
chmod +x /mnt/gentoo/install.sh
chroot /mnt/gentoo /bin/bash /install.sh

echo "#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero exit status
set -e

if [ '$PACKAGES' != 'minimal' ]; then
	# Getting the dotfiles
	mkdir /home/$USERNAME/git
	git clone https://github.com/saundersp/dotfiles.git /home/$USERNAME/git/dotfiles
fi

# Allow user to poweroff and reboot
echo -e 'permit nopass :wheel cmd poweroff\npermit nopass :wheel cmd reboot' | sudo tee -a /etc/doas.conf

case $PACKAGES in
	minimal) ;;
	server)
		# Enabling the dotfiles
		cd /home/$USERNAME/git/dotfiles
		sudo -u $USERNAME bash auto.sh server
		sudo bash auto.sh server
	;;
	virtual|laptop)
		# Enabling the dotfiles
		cd /home/$USERNAME/git/dotfiles
		sudo -u $USERNAME bash auto.sh
		sudo bash auto.sh

		# Getting the wallpaper
		mkdir /home/$USERNAME/Images
		cd /home/$USERNAME/Images
		wget -q --show-progress https://www.pixelstalk.net/wp-content/uploads/2016/07/HD-Astronaut-Wallpaper.jpg

		# Allow user to use brightnessctl
		test $PACKAGES == 'laptop' && echo 'permit nopass :wheel cmd brightnessctl' | sudo tee -a /etc/doas.conf
	;;
esac

# Removing the nopass option in doas
sudo sed -i '1s/nopass/persist/g' /etc/doas.conf

" > /mnt/gentoo/home/$USERNAME/install.sh
chmod +x /mnt/gentoo/home/$USERNAME/install.sh
chroot --userspec $USERNAME:$USERNAME /mnt/gentoo /bin/bash /home/$USERNAME/install.sh

# Cleaning leftovers
rm -f /mnt/gentoo/install.sh /mnt/gentoo/$STAGE_FILENAME /mnt/gentoo/home/$USERNAME/install.sh

reboot

