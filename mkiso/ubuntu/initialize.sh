#!/bin/bash
#
# initialize.sh
#

# set -x

###############################################################################

set -e

apt-get update
apt-get upgrade -y
apt-get autoremove --purge -y

dpkg-reconfigure locales
dpkg-reconfigure tzdata

###############################################################################

set +e

# user
echo -e '3450\n3450' | passwd
useradd -m -U -G sudo,adm -s /bin/zsh kzl
echo -e '3450\n3450' | passwd kzl

# network
systemctl enable systemd-networkd
systemctl enable systemd-resolved

# ssh
systemctl enable ssh
