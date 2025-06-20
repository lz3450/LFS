#!/bin/bash
#
# initialize.sh
#

################################################################################

echo -e 'raspi\nraspi' | passwd
useradd -m -U -G adm,dialout,sudo,audio,video -s /bin/zsh kzl
echo -e 'raspi\nraspi' | passwd kzl

systemctl disable wpa_supplicant.service
systemctl disable NetworkManager.service
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service
systemctl enable wpa_supplicant@wlan0.service
systemctl enable ssh.service
