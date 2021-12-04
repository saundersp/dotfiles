#!/usr/bin/env bash

source config.conf
bash preinstall.sh
useradd $USERNAME
mkdir -p /mnt/home/$USERNAME/git/
cp -r /root/dotfiles /mnt/home/$USERNAME/git
chown -R $USERNAME:$USERNAME /mnt/home/$USERNAME
cp /root/dotfiles/installer/config.conf /mnt
arch-chroot /mnt /home/$USERNAME/git/dotfiles/installer/root_install.sh
arch-chroot /mnt /usr/bin/runuser -u $USERNAME /home/$USERNAME/git/dotfiles/installer/user_install.sh
reboot
