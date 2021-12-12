#!/usr/bin/env bash

# Configuration (tweak to your liking)
USERNAME=saundersp
HOSTNAME=myarchbox
DISK=/dev/sda
DISK_LAST_SECTOR=
BOOT_PARITION_INDEX=1
ROOT_PARITION_INDEX=2
FONT_PATH=/usr/share/fonts
PACKAGES=virtual
SWAP_SIZE=4G
CRYPTED_DISK_NAME=luks_root
GRUB_ID=GRUB
DISK_PASSWORD=
ROOT_PASSWORD=
USER_PASSWORD=

test -z $DISK_PASSWORD && echo 'Enter DISK password : ' && read -s DISK_PASSWORD
test -z $ROOT_PASSWORD && echo 'Enter ROOT password : ' && read -s ROOT_PASSWORD
test -z $USER_PASSWORD && echo 'Enter USER password : ' && read -s USER_PASSWORD

# Updating the system clock
timedatectl set-ntp true

# List of disks
BOOT_PARTITION=$DISK$BOOT_PARITION_INDEX
ROOT_PARTITION=$DISK$ROOT_PARITION_INDEX

# Partition the disks
### Disk 1 - +128M - Bootable - UEFI Boot partition
### Disk 2 - Root partition
fdisk $DISK << EOF
n



+128M
t
uefi
a
n



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
mkdir -p /mnt/boot
mount $BOOT_PARTITION /mnt/boot

# Creating and mounting the swap file
fallocate -l $SWAP_SIZE /mnt/swap
chmod 0600 /mnt/swap
chown root /mnt/swap
mkswap /mnt/swap
swapon /mnt/swap

# Enable pacman's parallels downloads
sed -i 's/^#Para/Para/g' /etc/pacman.conf

# Settings faster pacman mirrors
pacman -Sy --noconfirm reflector rsync
reflector -a 48 -c $(curl -q ifconfig.co/country-iso) -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist

# Installing the common packages
pacstrap /mnt base linux linux-firmware fakeroot make gcc neovim doas grub efibootmgr neofetch which dmenu picom i3-gaps xorg-xinit xorg-server \
				xorg-xset feh alacritty git wget unzip firefox bash-completion reflector rsync nodejs npm python python-pip ripgrep man

# Installing the optional packages
if [ $PACKAGES == 'vrtual' ]; then
	pacstrap /mnt virtualbox-guest-utils networkmanager
elif [ $PACKAGES == 'laptop' ]; then
	pacstrap /mnt xf86-video-intel nvidia nvidia-utils nvidia-prime nvidia-settings keepassxc networkmanager-iwd ntfs-3g pulseaudio pulsemixer \
			pulseaudio-bluetooth bluez bluez-utils openssh xclip vlc intel-ucode lazygit
fi

# Copying optimized mirrors
cp /etc/pacman.conf /mnt/etc/pacman.conf
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

# Generating the mounting points
genfstab -U /mnt >> /mnt/etc/fstab

echo "
#!/usr/bin/env bash

npm i -g neovim npm-check-updates
pip install pynvim autopep8 flake8

if [ ! -d $FONT_PATH/Hasklig ]; then
	wget -q --show-progress https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Hasklig.zip
	mkdir $FONT_PATH/Hasklig
	unzip -q Hasklig.zip -d $FONT_PATH/Hasklig
	rm Hasklig.zip
fi

# Set the time zone
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime

# Setting hardware clock
hwclock --systohc

# Edit the file /etc/locale.gen and uncomment en_US.UTF-8 UTF-8 and ISO then use
sed -i 's/#en_US/en_US/g' /etc/locale.gen
locale-gen

# Set the LANG variable
echo LANG=en_US.UTF-8 > /etc/locale.conf

# Setting the keyboard layout
echo KEYMAP=fr > /etc/vconsole.conf

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
mkinitcpio -p linux

# Installing GRUB bootloader
grub-install --target x86_64-efi --efi-directory /boot --bootloader-id $GRUB_ID --recheck

# Prepare boot loader for LUKS
sed -i \"s,X=\\\"\\\",X=\\\"cryptdevice=UUID=\$(blkid $ROOT_PARTITION | cut -d \\\\\" -f 2):$CRYPTED_DISK_NAME root=/dev/mapper/$CRYPTED_DISK_NAME\\\",g\" /etc/default/grub

# Creating the GRUB configuration file
grub-mkconfig -o /boot/grub/grub.cfg

# Enabling networking
systemctl enable NetworkManager

# Enabling all threads during makepkg
sed -i \"s/^#MAKEFLAGS=\\\"-j2\\\"/MAKEFLAGS=\\\"-j\$(nproc)\\\"/g\" /etc/makepkg.conf
sed -i \"s/^COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -z - --threads=\$(nproc))/g\" /etc/makepkg.conf
" > /mnt/root/install.sh
chmod +x /mnt/root/install.sh
arch-chroot /mnt /root/install.sh

echo "
#!/usr/bin/env bash

# Getting the dotfiles
mkdir ~/git
git clone https://github.com/saundersp/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles
chmod +x auto.sh
chmod +x polybar/launch.sh
./auto.sh

mkdir ~/Images
curl https://www.pixelstalk.net/wp-content/uploads/2016/07/HD-Astronaut-Wallpaper.jpg > ~/Images/HD-Astronaut-Wallpaper.jpg

aur_install(){
	local PACKAGE_NAME=\$(basename \$1 .git)
	git clone \$1 ~/aur/\$PACKAGE_NAME
	cd ~/aur/\$PACKAGE_NAME
	makepkg -sri --noconfirm
}

aur_install https://aur.archlinux.org/polybar.git
if [ $PACKAGES == 'laptop' ]; then
	aur_install https://aur.archlinux.org/davmail.git
	aur_install https://aur.archlitnux.org/tor-browser.git
	aur_install https://aur.archlinux.org/font-manager.git
fi
" > /mnt/home/$USERNAME/install.sh
chmod +x /mnt/home/$USERNAME/install.sh
arch-chroot /mnt /usr/bin/runuser -u $USERNAME /home/$USERNAME/install.sh

echo -e "#!/usr/bin/env bash\ncd /home/$USERNAME/git/dotfiles\n./auto.sh" > /mnt/root/install.sh
arch-chroot /mnt /root/install.sh

# Cleaning leftovers
rm /mnt/root/install.sh /mnt/home/$USERNAME/install.sh

# Removing the nopass option in doas
sed -i 's/nopass/persist/g' /mnt/etc/doas.conf

reboot

