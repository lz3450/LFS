#!/bin/bash
#
# initialize.sh
#

set -e
# set -x

apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y
apt-get purge -y \
  grub-common
apt-get autoremove --purge -y

dpkg-reconfigure locales
dpkg-reconfigure tzdata

dpkg --get-selections | awk '{print $1}' | sed -e '/^linux-image-.+/d' -e '/^linux-modules-.+/d' -e 's/:amd64//g' \
  > bootstrap-installed-pkgs-$(. /etc/os-release && echo $UBUNTU_CODENAME).txt

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
