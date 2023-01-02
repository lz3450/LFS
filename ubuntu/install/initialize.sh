#! /bin/sh

set -e -u

apt update

apt install -y \
    linux-image-generic \
    linux-image-lowlatency \
    zsh \
    wget \
    nano \
    f2fs-tools \
    zsh-autosuggestions \
    zsh-syntax-highlighting

dpkg-reconfigure locales
dpkg-reconfigure tzdata

read -p 'hostname: ' HOSTNAME
echo $HOSTNAME > /etc/hostname

bootctl install --esp-path=/boot/efi

# passwd
echo "root password:"
passwd

useradd -m -U -G sudo -s /bin/zsh kzl
echo "kzl password:"
passwd kzl
