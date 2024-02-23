#!/bin/bash
#
# initialize.sh
#

set -e
# set -x

# package
tee /etc/apt/sources.list << EOF
deb http://us.archive.ubuntu.com/ubuntu jammy main restricted universe
deb-src http://us.archive.ubuntu.com/ubuntu jammy main restricted universe

deb http://us.archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe
deb-src http://us.archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe

deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe
deb-src http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe
EOF

apt update
apt upgrade -y
apt install -y \
    sudo \
    f2fs-tools \
    wpasupplicant \
    wget curl \
    nano \
    openssh-server \
    bash-completion \
    zsh \
    zsh-autosuggestions \
    zsh-syntax-highlighting

dpkg-reconfigure locales
dpkg-reconfigure tzdata

###############################################################################

set +e

read -p 'hostname: ' HOSTNAME
echo $HOSTNAME > /etc/hostname

# grml-zsh-config
wget -O /root/.zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc
echo 'source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> /root/.zshrc
echo 'source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh' >> /root/.zshrc

# passwd
echo "root password:"
passwd

useradd -m -U -G sudo -s /bin/zsh kzl
echo "kzl password:"
passwd kzl

# network
tee /etc/systemd/network/wireless.network << EOF
[Match]
Name=wl*

[Network]
DHCP=yes
EOF
tee /etc/systemd/network/ethernet.network << EOF
[Match]
Name=en*
Name=eth*

[Network]
DHCP=yes
EOF
tee /etc/wpa_supplicant/wpa_supplicant-wlo1.conf << EOF
network={
	ssid="LuckySKZLJ"
	psk=a8ba39d6dc7bc6e4984dcc45a386719fe42b5876dc4fd56c516a521615ee981c
}
network={
	ssid="S3Lab"
	psk=9dfacd4f5b26c7bfde13a184acb4b202eba5b2870cb2d6dccd10ac53012d0706
}
EOF

cat > /etc/netplan/network.yaml << EOF
network:
  version: 2
  renderer: NetworkManager
EOF

# boot
bootctl install --esp-path=/boot/efi

mkdir -p /boot/efi/loader/entries

tee /boot/efi/loader/loader.conf << EOF
timeout 3
console-mode max
default ubuntu.conf
EOF

tee /boot/efi/loader/entries/ubuntu.conf << EOF
title   Ubuntu 22.04
linux   /vmlinuz
initrd  /initrd.img
options root=PARTUUID="" rw
EOF
