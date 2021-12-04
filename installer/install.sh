#!/usr/bin/env bash

bash preinstall.sh
mkdir -p /mnt/home/_aspil0w/git/
cp -r /root/dotfiles /mnt/home/_aspil0w/git
arch-chroot /mnt /root/root_install.sh
arch-chroot /mnt /usr/bin/runuser -u _aspil0w /home/_aspil0w/user_install.sh

