#! /bin/sh

cd
apt install zsh wget nano zsh-autosuggestions zsh-syntax-highlighting
wget -O .zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc

cat > /etc/apt/sources.list << EOF
deb http://us.archive.ubuntu.com/ubuntu jammy main restricted universe
deb-src http://us.archive.ubuntu.com/ubuntu jammy main restricted universe

deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted
deb-src http://security.ubuntu.com/ubuntu/ jammy-security main restricted

deb http://us.archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe
deb-src http://us.archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe
EOF

apt update
apt upgrade

fallocate -l 8G /mnt/swapfile
mkswap /mnt/swapfile
chmod 600 /mnt/swapfile

# nano /etc/locale.gen
# locale-gen

dpkg-reconfigure locales
dpkg-reconfigure tzdata

read -p 'hostname: ' HOSTNAME
echo $HOSTNAME > /etc/hostname

nano /etc/hosts

bootctl install --esp-path=/boot/efi

cat > /boot/loader/loader.conf << EOF
timeout 3
console-mode max
default ubuntu
EOF

cat > /boot/loader/entries/ubuntu.conf << EOF
title   Ubuntu 22.04
linux   /vmlinuz
initrd  /initrd.img
options root=PARTUUID= rw
EOF

blkid >> /boot/loader/entries/ubuntu.conf

nano /boot/loader/entries/ubuntu.conf

# passwd
echo "root password:"
passwd

useradd -m -U -G wheel -s /bin/zsh kzl
echo "kzl password:"
passwd kzl

# zsh
echo 'source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh' | tee -a /root/.zshrc
echo 'source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' | tee -a /root/.zshrc
