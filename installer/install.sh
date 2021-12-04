#!/usr/bin/env bash

source config.conf
bash preinstall.sh
useradd $USERNAME
mkdir -p /mnt/home/$USERNAME/git/
chown -R $USERNAME:$USERNAME dotfiles
cp -r /root/dotfiles /mnt/home/$USERNAME/git
cp /root/dotfiles/installer/config.conf /mnt/root
arch-chroot /mnt /home/$USERNAME/git/dotfiles/installer/root_install.sh
arch-chroot /mnt /usr/bin/runuser -u $USERNAME /home/$USERNAME/git/dotfiles/installer/user_install.sh

