#!/bin/bash

set -e
# set -x

# package
apt-get clean
apt-get update
apt-get upgrade -y
apt-get install -y \
    ubuntu-raspi-settings

apt-get purge -y \
    ubuntu-advantage-tools

dpkg-reconfigure locales
dpkg-reconfigure tzdata

###############################################################################

set +e

update-initramfs -c -k all

# hostname
echo "RPi" > "$mountpoint"/etc/hostname

# user
echo -e '3450\n3450' | passwd
useradd -m -U -G sudo,adm -s /bin/zsh kzl
echo -e '3450\n3450' | passwd kzl

# network
tee /etc/systemd/network/eth0.network << EOF
[Match]
Name=en*
Name=eth*

[Network]
DHCP=yes
EOF
tee /etc/systemd/network/wlan0.network << EOF
[Match]
Name=wlan*

[Network]
DHCP=yes
EOF
tee /etc/wpa_supplicant/wpa_supplicant.conf << EOF
network={
	ssid="LuckySKZLJ"
	psk=51d8558a663cf1d191b42cd88d542e3847ce4da204196fa016c30728bc67f6e3
}
network={
	ssid="S3Lab"
	psk=9dfacd4f5b26c7bfde13a184acb4b202eba5b2870cb2d6dccd10ac53012d0706
}
EOF
cp /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant-wlan0.conf

systemctl enable systemd-networkd
systemctl enable systemd-resolved
systemctl enable wpa_supplicant@wlan0
systemctl enable ssh

# grml-zsh-config
wget -O /root/.zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc
echo 'source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> /root/.zshrc
echo 'source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh' >> /root/.zshrc
