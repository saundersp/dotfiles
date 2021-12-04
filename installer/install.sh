#!/usr/bin/env bash

bash preinstall.sh
mkdir -p /mnt/home/_aspil0w/git/
cp -r /root/dotfiles /mnt/home/_aspil0w/git
arch-chroot /mnt /home/_aspil0w/git/dotfiles/installer/root_install.sh
arch-chroot /mnt /usr/bin/runuser -u _aspil0w /home/_aspil0w/git/dotfiles/installer/user_install.sh

