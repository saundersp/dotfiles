#!/usr/bin/env bash

bash preinstall.sh
cp root_install.sh /mnt/root/root_install.sh
arch-chroot /mnt /root/root_install.sh
cp user_install.sh /mnt/home/_aspil0w/user_install.sh
arch-chroot /mnt /usr/bin/runuser -u _aspil0w /home/_aspil0w/user_install.sh

