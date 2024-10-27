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

test -z "$DISK_PASSWORD" && echo 'Enter DISK password : ' && read -r -s DISK_PASSWORD
test -z "$ROOT_PASSWORD" && echo 'Enter ROOT password : ' && read -r -s ROOT_PASSWORD
test -z "$USER_PASSWORD" && echo 'Enter USER password : ' && read -r -s USER_PASSWORD

# Exit immediately if a command exits with a non-zero exit status
set -e

# List of disks
BOOT_PARTITION="$DISK$PARTITION_SEPARATOR$BOOT_PARTITION_INDEX"
ROOT_PARTITION="$DISK$PARTITION_SEPARATOR$ROOT_PARTITION_INDEX"

# Partition the disks
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
mount /dev/mapper/"$CRYPTED_DISK_NAME" /mnt/gentoo
mount --mkdir "$BOOT_PARTITION" /mnt/gentoo/boot

# Creating and mounting the swap file
fallocate -l "$SWAP_SIZE" /mnt/gentoo/swap
chmod 0600 /mnt/gentoo/swap
chown root /mnt/gentoo/swap
mkswap /mnt/gentoo/swap
swapon /mnt/gentoo/swap

cd /mnt/gentoo

# links gentoo.org/downloads
STAGE_NAME="$(curl -s http://distfiles.gentoo.org/releases/amd64/autobuilds/latest-stage3-amd64-$STAGE_TYPE.txt | head -n 6 | tail -n 1 | cut -d' ' -f 1)"
wget http://distfiles.gentoo.org/releases/amd64/autobuilds/"$STAGE_NAME"
STAGE_FILENAME=$(basename "$STAGE_NAME")
tar xpf "$STAGE_FILENAME" --xattrs-include='*.*' --numeric-owner

mirrorselect -s 20 -o >> /mnt/gentoo/etc/portage/make.conf

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

# Removing the existing package.use
rm -rf /etc/portage/package.use /etc/portage/package.accept_keywords /etc/portage/package.mask
touch /etc/portage/package.use /etc/portage/package.accept_keywords /etc/portage/package.mask

# Configuring the USE flags
# Get all enabled flags : portageq envvar USE | xargs -n1
case $PACKAGES in
	minimal)
		# Global flags
		echo 'USE=\"minimal elogind -filecaps -caps\"' >> /etc/portage/make.conf
		echo -e 'sys-boot/grub mount -themes -fonts\napp-alternatives/sh -bash dash' > /etc/portage/package.use
	;;
	server)
		# Global flags
		echo 'USE=\"bash-completion minimal elogind -filecaps -caps\"' >> /etc/portage/make.conf
		echo -e 'sys-boot/grub mount -themes -fonts\napp-alternatives/sh -bash dash' > /etc/portage/package.use
	;;
	virtual)
		# Global flags
		echo 'USE=\"X bash-completion minimal elogind network threads -wifi -filecaps -caps\"' >> /etc/portage/make.conf
		# Local flags
		echo -e 'x11-misc/picom opengl -pcre -drm\nmedia-gfx/imagemagick jpeg\nx11-misc/polybar i3wm ipc network doc\nsys-boot/grub mount -themes -fonts
x11-base/xorg-server -minimal\napp-alternatives/sh -bash dash\napp-emulation/virtualbox-guest-additions gui

# required by app-portage/pfl-3.2-r2::gentoo[network-cron]
>=sys-apps/util-linux-2.38.1-r2 caps
# required by dev-lang/zig-0.10.1-r2::gentoo
# required by sys-fs/ncdu-2.2.2-r1::gentoo
>=sys-devel/lld-15.0.7 zstd
>=sys-devel/llvm-15.0.7 zstd

# required by x11-drivers/xf86-video-vmware-13.4.0::gentoo
# required by x11-base/xorg-drivers-21.1-r2::gentoo[video_cards_vmware]
# required by x11-base/xorg-server-21.1.7::gentoo[xorg]
# required by x11-drivers/xf86-input-libinput-1.2.1::gentoo
>=media-libs/mesa-23.0.0-r1 xa
# required by media-sound/pulseaudio-daemon-16.1-r6::gentoo[alsa-plugin,alsa]
# required by media-libs/libpulse-16.1-r2::gentoo
# required by media-sound/pulseaudio-16.1::gentoo
# required by media-sound/pulsemixer-1.5.1-r1::gentoo
>=media-plugins/alsa-plugins-1.2.7.1-r1 pulseaudio

# required by www-client/librewolf-110.0_p2::librewolf[system-libvpx]
>=media-libs/libvpx-1.12.0-r1 postproc
' > /etc/portage/package.use
		echo 'VIDEO_CARDS=\"vmware\"' >> /etc/portage/make.conf
	;;
	laptop)
		# Global flags
		echo 'USE=\"X bash-completion minimal elogind pulseaudio network threads wifi -filecaps -caps\"' >> /etc/portage/make.conf
		# Local flags
		echo -e 'x11-misc/picom opengl -pcre -drm\nmedia-gfx/imagemagick jpeg\nx11-misc/polybar i3wm ipc network doc\nsys-boot/grub mount -themes -fonts
x11-base/xorg-server -minimal\napp-alternatives/sh -bash dash'> /etc/portage/package.use
		echo 'VIDEO_CARDS=\"intel nvidia\"' >> /etc/portage/make.conf
	;;
esac

sed -i 's/COMMON_FLAGS=\\\"/COMMON_FLAGS=\\\"-march=native /g' /etc/portage/make.conf
echo -e \"MAKEOPTS=\\\"-j\$(nproc) -l\$(nproc)\\\"\nEMERGE_DEFAULT_OPTS=\\\"-j\$(nproc) -l\$(nproc)\\\"\nACCEPT_LICENSE=\\\"*\\\"\nACCEPT_KEYWORDS=\\\"~amd64\\\"\" >> /etc/portage/make.conf

emerge -q --noreplace app-misc/resolve-march-native

sed -i \"s/COMMON_FLAGS=\\\"-march=native /COMMON_FLAGS=\\\"\$(resolve-march-native) /g\" /etc/portage/make.conf
echo 'FEATURES=\"parallel-install parallel-fetch\"' >> /etc/portage/make.conf

# Apply the USE flags to the @world set
emerge -q --update --deep --newuse @world

# Removing outdated packages
emerge -cD

# Updating profile if neccessary
eselect gcc set 1
eselect binutils set 1
source /etc/profile

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
emerge -q --noreplace sys-fs/cryptsetup
rc-update add dmcrypt boot

# Compilation and installation of the kernel
emerge -q --noreplace sys-kernel/gentoo-sources sys-kernel/installkernel
eselect kernel set 1
cd /usr/src/linux
wget https://raw.githubusercontent.com/saundersp/dotfiles/main/installer/${PACKAGES^^}.config -O .config
make olddefconfig
make -j\$(nproc) -l\$(nproc)
make modules_install -j\$(nproc)
make install

# Building the kernel and initramfs
emerge -q --noreplace sys-kernel/genkernel
genkernel --luks initramfs

# Installing the firmware
emerge -q --noreplace sys-kernel/linux-firmware

# Setting up the fstab auto mouting
echo \"
UUID=\$(blkid -s UUID -o value $BOOT_PARTITION) /boot vfat defaults,noatime 0 2
UUID=\$(blkid -s UUID -o value /dev/mapper/$CRYPTED_DISK_NAME) / ext4 defaults,noatime 0 1
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
emerge -q --noreplace net-misc/netifrc net-misc/dhcpcd
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
emerge -q --noreplace app-admin/doas
echo -e 'permit nopass :wheel' > /etc/doas.conf

# Replace sudo
ln -s /usr/bin/doas /usr/bin/sudo

# Setup keyboard for OpenRC
sed -i 's/\"us\"/\"$KEYMAP\"/g' /etc/conf.d/keymaps

# Setup logging system
emerge -q --noreplace app-admin/sysklogd
rc-update add sysklogd default

# Getting the filesystems packages
emerge -q --noreplace sys-fs/e2fsprogs sys-fs/dosfstools

# Installing the bootloader
echo 'GRUB_PLATFORMS=\"efi-64\"' >> /etc/portage/make.conf
emerge -q --noreplace sys-boot/grub

# Prepare boot loader for LUKS
sed -i \"s,^#GRUB_CMDLINE_LINUX=\\\"\\\",GRUB_CMDLINE_LINUX=\\\"quiet crypt_root=UUID=\$(blkid -s UUID -o value $ROOT_PARTITION) root=/dev/mapper/root keymap=$KEYMAP\\\",g\" /etc/default/grub

# Enable os-prober if laptop
if [ '$PACKAGES' == 'laptop' ]; then
	echo GRUB_DISABLE_OS_PROBER=false >> /etc/default/grub
	emerge -q --noreplace sys-boot/os-prober
	os-prober
fi

# Installing GRUB bootloader
grub-install --target x86_64-efi --efi-directory /boot --removable --bootloader-id $GRUB_ID --recheck

# Creating the GRUB configuration file
grub-mkconfig -o /boot/grub/grub.cfg

# Installing minimal packages
emerge -q --noreplace sys-auth/elogind app-eselect/eselect-python

# Change default editor
eselect pager set less

install_server(){
	emerge -q --noreplace app-eselect/eselect-repository dev-vcs/git
	eselect repository enable guru
	emaint -r guru sync

	eselect repository add saundersp-overlay git https://git.saundersp.com/saundersp/saundersp-overlay.git
	emaint -r saundersp-overlay sync

	emerge -q --noreplace app-misc/fastfetch app-editors/neovim sys-apps/which net-misc/wget app-arch/unzip app-shells/bash-completion \
		net-libs/nodejs dev-lang/python sys-apps/ripgrep sys-apps/man-db dev-python/pip sys-process/btop dev-lang/go app-misc/tmux \
		app-misc/ranger dev-python/pynvim app-portage/mirrorselect app-portage/pfl app-portage/gentoolkit sys-apps/fd sys-fs/ncdu \
		app-portage/eix dev-vcs/lazygit app-containers/lazydocker dev-python/pipx

	# Update eix packages cache
	eix-update
	eix-remote update

	# Change default editor to neovim
	eselect vi set nvim
	eselect editor set vi
	eselect visual set vi

	# Creating user's custom packages location
	mkdir /usr/local/src

	# Installing npm dependencies
	npm i -g neovim npm-check-updates
}
install_ihm(){
	install_server
	emerge -q --noreplace x11-misc/picom x11-wm/i3 x11-apps/xinit x11-base/xorg-server x11-apps/xset media-gfx/feh \
		x11-misc/polybar x11-apps/xrandr x11-misc/xclip x11-apps/setxkbmap app-eselect/eselect-repository \
		x11-libs/libXinerama media-gfx/ueberzugpp media-gfx/imagemagick media-sound/pulsemixer

	eselect repository add librewolf git https://codeberg.org/librewolf/gentoo.git
	emaint -r librewolf sync
	#emerge -q --noreplace www-client/librewolf

	# Getting the Hasklig font
	LATEST_TAG=\$(curl https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep tag_name | cut -d \\\" -f 4)
	wget -q --show-progress https://github.com/ryanoasis/nerd-fonts/releases/download/\"\$LATEST_TAG\"/Hasklig.zip
	mkdir /usr/share/fonts/Hasklig
	unzip -q Hasklig.zip -d /usr/share/fonts/Hasklig
	echo \$LATEST_TAG > /usr/share/fonts/Hasklig/VERSION
	rm Hasklig.zip
}
install_dotfiles(){
	# Installing pipx packages
	pipx install dooit

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
	magick convert -crop '2560x1440!+0+70' HD-Astronaut-Wallpaper.jpg WanderingAstronaut.png
	rm HD-Astronaut-Wallpaper.jpg
	echo -e '#!/bin/sh\nfeh --bg-fill ~/Images/WanderingAstronaut.png' > ~/.fehbg
	chmod +x ~/.fehbg
}
export -f install_dotfiles

case $PACKAGES in
	virtual)
		install_ihm
		emerge -q --noreplace app-emulation/virtualbox-guest-additions
		rc-update add virtualbox-guest-additions default
		usermod -aG vboxguest $USERNAME
		su $USERNAME -c \"install_dotfiles $PACKAGES\"
	;;
	server)
		install_server
		su $USERNAME -c \"install_dotfiles $PACKAGES\"
		;;
	minimal) ;;
	laptop)
		install_ihm
		emerge -q --noreplace x11-apps/xbacklight net-misc/connman net-wireless/wpa_supplicant net-vpn/wireguard-tools
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
rm -f /mnt/gentoo/install.sh /mnt/gentoo/"$STAGE_FILENAME" "$0"

reboot

