#!/usr/bin/env bash
# Can't bind to /bin/sh because of export -f ...

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

test -z $DISK_PASSWORD && echo 'Enter DISK password : ' && read -r -s DISK_PASSWORD
test -z $ROOT_PASSWORD && echo 'Enter ROOT password : ' && read -r -s ROOT_PASSWORD
test -z $USER_PASSWORD && echo 'Enter USER password : ' && read -r -s USER_PASSWORD

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
echo -e "MAKEOPTS=\"-j$(nproc)\"\nACCEPT_LICENSE=\"*\"\nACCEPT_KEYWORDS=\"~amd64\"" >> /mnt/gentoo/etc/portage/make.conf

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

# Enable faster startup times
sed 's/#rc_parallel=\\\"NO\\\"/rc_parallel=\"YES\\\"/' -i /etc/rc.conf

# Updating the Gentoo ebuild repository
emerge -q --sync

# Choosing the default minimal profile
eselect profile set 1

# Apply the default USE flags to the @world set
emerge -q --update --deep --newuse @world

# Removing the existing package.use
rm -rf /etc/portage/package.use /etc/portage/package.accept_keywords /etc/portage/package.mask
touch /etc/portage/package.use /etc/portage/package.accept_keywords /etc/portage/package.mask

# Configuring the USE flags
# Get all enabled flags : portageq envvar USE | xargs -n1
# Note : use 'less /var/db/repos/gentoo/profiles/use.desc' to get a description of each variables
case $PACKAGES in
	minimal)
		# Global flags
		echo 'USE=\"elogind\"' >> /etc/portage/make.conf
	;;
	server)
		# Global flags
		echo 'USE=\"X bash-completion elogind python\"' >> /etc/portage/make.conf
	;;
	virtual)
		# Global flags
		echo 'USE=\"X bash-completion elogind python\"' >> /etc/portage/make.conf
		# Local flags
		echo -e 'x11-misc/polybar i3wm\nmedia-libs/libvpx postproc' > /etc/portage/package.use
	;;
	laptop)
		# Global flags
		echo 'USE=\"X bash-completion connman elogind pulseaudio python\"' >> /etc/portage/make.conf
		# Local flags
		echo -e 'x11-misc/polybar i3wm\nmedia-libs/libvpx postproc' > /etc/portage/package.use
	;;
esac

# Setting the timezone
echo $TIMEZONE > /etc/timezone
emerge -q --config sys-libs/timezone-data

# Setting the locale
echo -e '$LOCALE.UTF-8 UTF-8\n$LOCALE ISO-8859-1' >> /etc/locale.gen
locale-gen
eselect locale set \$(eselect locale list | grep $LOCALE.utf8 | grep -oP '\[\K\d*(?=\])')
env-update
source /etc/profile

# Installing cryptsetup
emerge -q sys-fs/cryptsetup
rc-update add dmcrypt boot

# Compilation and installation of the kernel
emerge -q sys-kernel/gentoo-sources
eselect kernel set 1
#cd /usr/src/linux
#make menuconfig
#make -j\$(nproc)
#make modules_install -j\$(nproc)
#make install
#emerge -q sys-apps/pciutils

# Building the kernel and initramfs
emerge -q sys-kernel/genkernel
genkernel --luks all
#genkernel --luks initramfs

# Installing the firmware
emerge -q sys-kernel/linux-firmware

# Setting up the fstab auto mouting
echo \"
UUID=\$(blkid -s UUID -o value $BOOT_PARTITION) /boot vfat defaults,noatime 0 2
UUID=\$(blkid -s UUID -o value /dev/mapper/$CRYPTED_DISK_NAME) / ext4 noatime 0 1
/swap none swap defaults 0 0
\" >> /etc/fstab

# Setting the hostname
sed -i 's/localhost/$HOSTNAME/g' /etc/conf.d/hostname
cat << EOF
127.0.0.1	localhost
::1		localhost
127.0.1.1	$HOSTNAME.localdomain $HOSTNAME
EOF > /etc/hosts

# Setting network
emerge -q --noreplace net-misc/netifrc
emerge -q net-misc/dhcpcd
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
emerge -q app-admin/doas
echo -e 'permit nopass :wheel\npermit nopass :wheel cmd poweroff\npermit nopass :wheel cmd reboot' > /etc/doas.conf

# Replace sudo
ln -s /usr/bin/doas /usr/bin/sudo

# Setup keyboard for OpenRC
sed -i 's/\"us\"/\"$KEYMAP\"/g' /etc/conf.d/keymaps

# Setup logging system
emerge -q app-admin/sysklogd
rc-update add sysklogd default

# Getting the filesystems packages
emerge -q sys-fs/e2fsprogs sys-fs/dosfstools

# Installing the bootloader
echo 'GRUB_PLATFORMS=\"efi-64\"' >> /etc/portage/make.conf
emerge -q sys-boot/grub

# Prepare boot loader for LUKS
sed -i \"s,^#GRUB_CMDLINE_LINUX=\\\"\\\",GRUB_CMDLINE_LINUX=\\\"quiet crypt_root=UUID=\$(blkid -s UUID -o value $ROOT_PARTITION) root=/dev/mapper/root keymap=$KEYMAP\\\",g\" /etc/default/grub

# Enable os-prober if laptop
if [ '$PACKAGES' == 'laptop' ]; then
	echo GRUB_DISABLE_OS_PROBER=false >> /etc/default/grub
	emerge -q sys-boot/os-prober
	os-prober
fi

# Installing GRUB bootloader
grub-install --target x86_64-efi --efi-directory /boot --removable --bootloader-id $GRUB --recheck

# Creating the GRUB configuration file
grub-mkconfig -o /boot/grub/grub.cfg

# Installing minimal packages
emerge -q sys-auth/elogind sys-apps/which

install_server(){
	emerge -q app-misc/neofetch app-editors/neovim sys-apps/which dev-vcs/git net-misc/wget app-arch/unzip app-shells/bash-completion net-libs/nodejs \
			dev-lang/python sys-apps/ripgrep sys-apps/man-db dev-python/pip sys-process/htop dev-lang/go app-misc/tmux app-misc/ranger

	# Creating user's custom packages location
	mkdir /usr/local/src

	# Compiling lazygit
	cd /usr/local/src
	git clone https://github.com/jesseduffield/lazygit.git
	cd lazygit
	sudo -u $USERNAME go install
	mv /home/$USERNAME/go/bin/lazygit /usr/bin/lazygit

	# Compiling lazygit
	cd ..
	git clone https://github.com/jesseduffield/lazydocker.git
	cd lazydocker
	sudo -u $USERNAME go install
	mv /home/$USERNAME/go/bin/lazydocker /usr/bin/
	cd \$HOME

	# Installing npm dependencies
	npm i -g neovim npm-check-updates

	# Installing pip dependencies
	sudo -u $USERNAME pip install --user pynvim autopep8 flake8
	ls /home/$USERNAME/.local/bin | xargs -I{} sudo mv /home/$USERNAME/.local/bin/{} /usr/bin/{}
}
install_ihm(){
	install_server
	emerge -q x11-misc/dmenu x11-misc/picom x11-wm/i3-gaps x11-apps/xinit x11-base/xorg-server x11-apps/xset media-gfx/feh \
			x11-misc/polybar x11-apps/xrandr x11-misc/xclip x11-apps/setxkbmap app-eselect/eselect-repository \
			x11-libs/libXinerama media-gfx/ueberzug media-gfx/imagemagick

	eselect repository add librewolf git https://gitlab.com/librewolf-community/browser/gentoo.git
	emaint -r librewolf sync
	emerge -q www-client/librewolf

	# Getting the Hasklig font
	wget -q --show-progress https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Hasklig.zip
	mkdir /usr/share/fonts/Hasklig
	unzip -q Hasklig.zip -d /usr/share/fonts/Hasklig
	rm Hasklig.zip
}
install_dotfiles(){
	# Getting the dotfiles
	mkdir ~/git
	git clone https://github.com/saundersp/dotfiles.git ~/git/dotfiles

	# Enabling the dotfiles
	cd ~/git/dotfiles
	./auto.sh \$1
	sudo bash auto.sh \$1

	# Getting the wallpaper
	mkdir ~/Images
	cd ~/Images
	wget -q --show-progress https://www.pixelstalk.net/wp-content/uploads/2016/07/HD-Astronaut-Wallpaper.jpg
	convert HD-Astronaut-Wallpaper.jpg WanderingAstronaut.png
	rm Astronaut-Wallpaper.jpg
}
export -f install_dotfiles

case $PACKAGES in
	virtual)
		install_ihm
		emerge -q app-emulation/virtualbox-guest-additions
		su $USERNAME -c \"install_dotfiles $PACKAGES\"
	;;
	server)
		install_server
		su $USERNAME -c \"install_dotfiles $PACKAGES\"
		;;
	minimal) ;;
	laptop)
		install_ihm
		emerge -q x11-apps/xbacklight net-misc/connman net-wireless/wpa_supplicant net-vpn/wireguard-tools
		su $USERNAME -c \"install_dotfiles $PACKAGES\"
	;;
esac

# Start elogind service at boot
rc-update add elogind boot

# Removing the nopass option in doas
sed -i '1s/nopass/persist/g' /etc/doas.conf

" > /mnt/gentoo/install.sh
chmod +x /mnt/gentoo/install.sh
chroot /mnt/gentoo /bin/bash /install.sh

# Cleaning leftovers
rm -f /mnt/gentoo/install.sh /mnt/gentoo/$STAGE_FILENAME $0

reboot

