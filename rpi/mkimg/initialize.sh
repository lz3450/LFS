#!/bin/bash

set -e

# package
apt update || :
apt install -y \
    gnupg \
    wget curl \
    dialog \
    wpasupplicant \
    git \
    zsh zsh-autosuggestions zsh-syntax-highlighting \
    locales \
    openssh-server \
    sudo
wget -qO - http://archive.raspberrypi.org/debian/raspberrypi.gpg.key | apt-key add -
apt update
apt upgrade -y
apt install -y \
    raspberrypi-archive-keyring \
    raspberrypi-bootloader \
    raspberrypi-kernel \
    raspberrypi-kernel-headers \
    raspberrypi-sys-mods \
    raspi-config \
    raspi-gpio \
    raspinfo \
    rpi-update \
    pi-bluetooth \
    firmware-realtek \
    vl805fw \
    firmware-misc-nonfree \
    firmware-libertas \
    firmware-brcm80211 \
    firmware-atheros

# user
echo -e '3450\n3450' | passwd
useradd -m -U -G sudo -s /bin/zsh kzl
echo -e '3450\n3450' | passwd kzl

###############################################################################

# zsh
wget https://deb.grml.org/pool/main/g/grml-etc-core/grml-etc-core_0.18.0.tar.gz || :
if [ -f grml-etc-core_0.18.0.tar.gz ]; then
    tar -xf grml-etc-core_0.18.0.tar.gz
    pushd grml-etc-core-0.18.0
    install -Dm644 etc/skel/.zshrc /etc/skel/.zshrc
    install -Dm644 etc/zsh/keephack /etc/zsh/keephack
    install -Dm644 etc/zsh/zshrc /etc/zsh/zshrc
    popd
    rm -rf grml-etc-core-0.18.0 grml-etc-core_0.18.0.tar.gz
fi

echo 'source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh' | tee -a /root/.zshrc
echo 'source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' | tee -a /root/.zshrc
echo 'source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh' | sudo -u kzl tee -a /home/kzl/.zshrc
echo 'source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' | sudo -u kzl tee -a /home/kzl/.zshrc

# locale
sed -i '/^# en_US.UTF-8/s/^#//' /etc/locale.gen
sed -i '/^# zh_CN.UTF-8/s/^#//' /etc/locale.gen
echo 'LANG=en_US.UTF-8' | tee -a /etc/locale.conf
locale-gen

# environment variables
sudo -u kzl tee -a /home/kzl/.zshenv << EOF 
typeset -U PATH path
path=("$HOME/.local/bin" "\$path[@]")
export PATH
EOF

# time
# timedatectl set-ntp 1

# network
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
