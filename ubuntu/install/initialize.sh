#!/bin/bash
#
# initialize.sh
#

set -e
# set -x

apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y

dpkg-reconfigure locales
dpkg-reconfigure tzdata

###############################################################################

set +e

# passwd
echo "root password:"
passwd

useradd -m -U -G sudo -s /bin/zsh kzl
echo "kzl password:"
passwd kzl

# network
systemctl enable systemd-networkd.service

# boot
bootctl install --esp-path=/boot/efi
