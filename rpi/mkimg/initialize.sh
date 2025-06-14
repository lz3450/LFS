#!/bin/bash
#
# initialize.sh
#

################################################################################

update-initramfs -c -k all

echo -e 'raspi\nraspi' | passwd
useradd -m -U -G sudo,adm -s /bin/zsh kzl
echo -e 'raspi\nraspi' | passwd kzl

systemctl enable systemd-networkd
systemctl enable systemd-resolved
systemctl enable wpa_supplicant@wlan0
systemctl enable ssh
