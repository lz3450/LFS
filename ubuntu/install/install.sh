#!/bin/bash

set -e -u

# EFI: /boot/efi

debootstrap jammy /mnt http://us.archive.ubuntu.com/ubuntu

for fs in dev sys proc run; do
    mount --rbind /$fs /mnt/$fs
    mount --make-rslave /mnt/$fs
done

cat > /mnt/etc/apt/sources.list << EOF
deb http://us.archive.ubuntu.com/ubuntu jammy main restricted universe
deb-src http://us.archive.ubuntu.com/ubuntu jammy main restricted universe

deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted
deb-src http://security.ubuntu.com/ubuntu/ jammy-security main restricted

deb http://us.archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe
deb-src http://us.archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe
EOF

fallocate -l 16G /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile

# boot
mkdir -p /mnt/boot/efi/loader/entries

cat > /mnt/boot/efi/loader/loader.conf << EOF
timeout 3
console-mode max
default ubuntu
EOF

cat > /mnt/boot/efi/loader/entries/ubuntu.conf << EOF
title   Ubuntu 22.04
linux   /vmlinuz
initrd  /initrd.img
options root="PARTUUID=" rw
EOF

blkid >> /boot/efi/loader/entries/ubuntu.conf
nano /boot/efi/loader/entries/ubuntu.conf

# zsh
wget -O /mnt/root/.zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc
echo 'source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh' | tee -a /root/.zshrc
echo 'source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' | tee -a /root/.zshrc

# environment variables
cat > ~/.zshenv << EOF 
typeset -U PATH path
path=("$HOME/.local/bin" "\$path[@]")
export PATH
fpath=(/usr/local/share/zsh/site-functions $fpath)
EOF

cp initialize.sh /mnt/root
genfstab -t PARTUUID /mnt > /mnt/etc/fstab

LANG=C.UTF-8 PATH=/usr/bin:/usr/sbin chroot /mnt /bin/bash
