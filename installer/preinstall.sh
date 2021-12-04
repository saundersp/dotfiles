#!/bin/bash

# Getting the config file
source config.conf

# Updating the system clock
timedatectl set-ntp true

# List of disks
BOOT_PARTITION=$DISK\1
ROOT_PARTITION=$DISK\2

# Partition the disks
### Disk 1 - +128M - Bootable - UEFI Boot partition
### Disk 2 - Root partition
fdisk $DISK << EOF
n



+128M
t
uefi
n




w
EOF

# Encrypting the root partition
cryptsetup luksFormat -y -v  $ROOT_PARTITION
cryptsetup open $ROOT_PARTITION luks_root

# Formatting the partitions
mkfs.fat -n "UEFI Boot" -F 32 $BOOT_PARTITION
mkfs.ext4 -L root /dev/mapper/luks_root

# Mounting the file systems
mount /dev/mapper/luks_root /mnt
mkdir -p /mnt/boot && mount $BOOT_PARTITION /mnt/boot

# Creating and mounting the swap file
fallocate -l 4GB /mnt/swap
chmod 0600 /mnt/swap
chown root /mnt/swap
mkswap /mnt/swap
swapon /mnt/swap

# Enable pacman's parallels downloads
sed -i 's/^#Para/Para/g' /etc/pacman.conf

# Settings faster pacman mirrors
pacman -Sy --noconfirm reflector rsync
reflector -a 48 -c $(curl -q ifconfig.co/country-iso) -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist

# Installing the packages
pacstrap /mnt base linux linux-firmware fakeroot binutils make gcc pkgconf neovim doas networkmanager grub efibootmgr \
			neofetch which dmenu picom i3-gaps xorg-xinit xorg-server xorg-xset feh alacritty git wget unzip firefox \
			virtualbox-guest-utils bash-completion reflector rsync nodejs npm python python-pip ripgrep

# Copying optimized mirrors
cp /etc/pacman.conf /mnt/etc/pacman.conf
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

# Generating the mounting points
genfstab -U /mnt >> /mnt/etc/fstab

