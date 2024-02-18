#!/bin/bash

set -e
# set -x

# package
apt clean
apt update
apt install -y \
    sudo \
    f2fs-tools \
    systemd-timesyncd \
    wpasupplicant \
    gnupg \
    wget curl \
    bash-completion \
    nano \
    openssh-server \
    zsh \
    zsh-syntax-highlighting \
    zsh-autosuggestions \
    linux-firmware-raspi \
    ubuntu-raspi-settings \
    # linux-raspi \
    # flash-kernel \
    # rpi-eeprom
apt upgrade -y

dpkg-reconfigure locales
dpkg-reconfigure tzdata

###############################################################################

set +e

# hostname
echo "RPi" > "$mountpoint"/etc/hostname

# grml-zsh-config
wget -O /root/.zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc
echo 'source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> /root/.zshrc
echo 'source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh' >> /root/.zshrc

# user
echo -e '3450\n3450' | passwd
useradd -m -U -G sudo,adm -s /bin/zsh kzl
echo -e '3450\n3450' | passwd kzl

# environment variables
tee /home/kzl/.zshenv << EOF
typeset -U PATH path
path=("\$HOME/.local/bin" "\$path[@]")
export PATH
EOF
chown kzl:kzl /home/kzl/.zshenv

# time
# timedatectl set-ntp 1

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
Name=wlan0

[Network]
DHCP=yes
EOF
tee /etc/wpa_supplicant/wpa_supplicant-wlan0.conf << EOF
network={
	ssid="LuckySKZLJ"
	psk=a8ba39d6dc7bc6e4984dcc45a386719fe42b5876dc4fd56c516a521615ee981c
}
network={
	ssid="S3Lab"
	psk=9dfacd4f5b26c7bfde13a184acb4b202eba5b2870cb2d6dccd10ac53012d0706
}
EOF

systemctl enable systemd-networkd
systemctl enable systemd-resolved
systemctl enable wpa_supplicant@wlan0
systemctl enable ssh
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
