#!/usr/bin/bash

# pacman -Sy pacman-contrib
# cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
# rankmirrors -n 0 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist

pacstrap -c -G -M -- /mnt \
    arch-install-scripts base diffutils dosfstools e2fsprogs gptfdisk grml-zsh-config less libfido2 libsigsegv libusb-compat linux linux-firmware man-db mdadm mtools nano nvme-cli openssh parted rsync screen smartmontools sudo tmux usbutils vim wpa_supplicant zsh zsh-autosuggestions zsh-syntax-highlighting

fallocate -l 8G /mnt/swapfile
mkswap /mnt/swapfile
chmod 600 /mnt/swapfile
ln -sf /mnt/swapfile /swapfile
swapon /swapfile

genfstab -U /mnt >> /mnt/etc/fstab

cp -rf initialize.sh user_scripts kzl-linux.conf loader.conf /mnt/root
