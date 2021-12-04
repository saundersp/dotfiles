#!/usr/bin/env bash

# Getting the config file
source config.conf
ROOT_PARTITION=$DISK\2

npm i -g neovim npm-check-updates
pip install pynvim autopep8 flake8

if [ ! -d $FONT_PATH/Hasklig ]; then
	wget -q --show-progress https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Hasklig.zip
	mkdir $FONT_PATH/Hasklig && unzip -q Hasklig.zip -d $FONT_PATH/Hasklig
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
echo -e "
127.0.0.1    localhost
::1          localhost
127.0.1.1    $HOSTNAME.localdomain $HOSTNAME
" >> /etc/hosts

# Setting a root password
echo Enter root password
passwd

# Adding user and creating home directory
useradd -G wheel $USERNAME

# Setting a user password
echo Enter user password
passwd $USERNAME

# Enable the wheel group to use doas
echo "permit persist :wheel" > /etc/doas.conf

# Replace sudo
ln -s /usr/bin/doas /usr/bin/sudo

# Initialize Initiramfs
sed -i 's/modconf block filesystems /keyboard keymap modconf block encrypt filesystems /g' /etc/mkinitcpio.conf
mkinitcpio -p linux

# Installing GRUB bootloader
grub-install --target x86_64-efi --efi-directory /boot --bootloader-id GRUB --recheck

# Get UUID
UUID=$(blkid | grep $ROOT_PARTITION | cut -d \" -f 2)

# Prepare boot loader for LUKS
sed -i "s,X=\"\",X=\"cryptdevice=UUID=$UUID:luks_root root=/dev/mapper/luks_root\",g" /etc/default/grub

# Creating the GRUB configuration file
grub-mkconfig -o /boot/grub/grub.cfg

# Enabling networking
systemctl enable NetworkManager

