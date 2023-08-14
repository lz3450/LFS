#!/bin/bash

set -e
# set -x

# package
apt update
apt install -y \
    sudo \
    f2fs-tools \
    systemd-resolved \
    systemd-timesyncd \
    wpasupplicant \
    gnupg \
    wget curl \
    dialog \
    locales \
    openssh-server \
    zsh \
    zsh-syntax-highlighting \
    zsh-autosuggestions
apt upgrade -y

wget -qO /etc/apt/trusted.gpg.d/raspberrypi.gpg.key http://archive.raspberrypi.org/debian/raspberrypi.gpg.key
apt update
apt install -y \
    raspberrypi-archive-keyring \
    raspberrypi-bootloader \
    raspberrypi-kernel \
    raspi-config \
    raspi-gpio \
    rpi-eeprom \
    rpi-eeprom-images \
    rpiboot

dpkg-reconfigure locales
dpkg-reconfigure tzdata

# locale
# sed -i '/^# en_US.UTF-8/s/^#//' /etc/locale.gen
# sed -i '/^# zh_CN.UTF-8/s/^#//' /etc/locale.gen
# echo 'LANG=en_US.UTF-8' | tee /etc/locale.conf
# locale-gen

###############################################################################

set +e

# grml-zsh-config
wget -O /root/.zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc
echo 'source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> /root/.zshrc
echo 'source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh' >> /root/.zshrc

# user
echo -e '3450\n3450' | passwd
useradd -m -U -G sudo -s /bin/zsh kzl
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
EOF

systemctl enable systemd-networkd
systemctl enable systemd-resolved
systemctl enable wpa_supplicant@wlan0
systemctl enable ssh
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
