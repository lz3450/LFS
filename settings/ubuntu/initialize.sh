#! /bin/sh

cd
apt install zsh wget nano
wget -O .zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc

cat << EOF > /etc/apt/sources.list
deb http://us.archive.ubuntu.com/ubuntu disco main restricted universe
deb-src http://us.archive.ubuntu.com/ubuntu disco main restricted universe

deb http://security.ubuntu.com/ubuntu/ disco-security main restricted
deb-src http://security.ubuntu.com/ubuntu/ disco-security main restricted

deb http://us.archive.ubuntu.com/ubuntu/ disco-updates main restricted universe
deb-src http://us.archive.ubuntu.com/ubuntu/ disco-updates main restricted universe
EOF

apt update
apt upgrade

fallocate -l 8G /mnt/swapfile
mkswap /mnt/swapfile
chmod 600 /mnt/swapfile

nano /etc/locale.gen
locale-gen

cat << EOF > /etc/fstab
UUID=   /boot   vfat    defaults        0 2
UUID=   /       ext4    defaults        0 1
/swapfile       none    swap    defaults        0 0
EOF

nano /etc/hosts

bootctl install --path=/boot
nano /boot/loader/loader.conf

cat << EOF > /boot/loader/entries/Ubuntu.conf
title   Ubuntu
linux   /
initrd  /
options root=UUID= rw
EOF

nano /boot/loader/entries/Ubuntu.conf

passwd
