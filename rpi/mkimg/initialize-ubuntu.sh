#!/bin/bash

set -e
# set -x

# package
apt update
apt install -y \
    f2fs-tools \
    gnupg \
    wget curl \
    dialog \
    wpasupplicant \
    zsh \
    locales \
    openssh-server \
    sudo \
    systemd-timesyncd \
    linux-firmware-raspi \
    linux-raspi \
    linux-image-raspi \
    linux-headers-raspi \
    linux-firmware-raspi
apt upgrade -y

# grml-zsh-config
wget -O rootfs/root/.zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc
wget -O rootfs/root/.zsh-autosuggestions.zsh https://raw.githubusercontent.com/zsh-users/zsh-autosuggestions/master/zsh-autosuggestions.zsh
wget -O rootfs/root/.zsh-syntax-highlighting.zsh https://raw.githubusercontent.com/zsh-users/zsh-syntax-highlighting/master/zsh-syntax-highlighting.zsh
echo 'source /root/.zsh-syntax-highlighting.zsh' >> rootfs/root/.zshrc
echo 'source /root/.zsh-autosuggestions.zsh' >> rootfs/root/.zshrc

# user
echo -e '3450\n3450' | passwd
useradd -m -U -G sudo -s /bin/zsh kzl
echo -e '3450\n3450' | passwd kzl

###############################################################################

dpkg-reconfigure locales
dpkg-reconfigure tzdata

# locale
# sed -i '/^# en_US.UTF-8/s/^#//' /etc/locale.gen
# sed -i '/^# zh_CN.UTF-8/s/^#//' /etc/locale.gen
# echo 'LANG=en_US.UTF-8' | tee /etc/locale.conf
# locale-gen

# environment variables
tee /home/kzl/.zshenv << EOF 
typeset -U PATH path
path=("\$HOME/.local/bin" "\$path[@]" "/usr/local/sbin" "/usr/sbin" "/sbin")
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
EOF

systemctl enable systemd-networkd systemd-resolved wpa_supplicant@wlan0 ssh
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
