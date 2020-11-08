#!/bin/bash

pacman -Sy pacman-contrib
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
rankmirrors -n 0 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist

pacstrap /mnt base linux-lts linux-firmware dhcpcd base-devel zsh grml-zsh-config zsh-autosuggestions zsh-syntax-highlighting dialog wpa_supplicant intel-ucode nano

fallocate -l 8G /mnt/swapfile
mkswap /mnt/swapfile
chmod 600 /mnt/swapfile
ln -sf /mnt/swapfile /swapfile
swapon /swapfile

genfstab -U /mnt >> /mnt/etc/fstab

cp -rf initialize.sh efi.sh user_scripts archlinux.conf loader.conf /mnt/root

