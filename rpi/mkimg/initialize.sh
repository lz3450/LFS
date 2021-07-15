#!/bin/bash

set -e
# set -x

# package
apt-get update || :
apt-get install -y \
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
apt-get update
apt-get upgrade -y
apt-get install -y \
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

# zsh
wget -O .zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc
install -Dm644 .zshrc /etc/skel/.zshrc
install -Dm644 .zshrc /etc/zsh/zshrc

# user
echo -e '3450\n3450' | passwd
useradd -m -U -G sudo -s /bin/zsh kzl
echo -e '3450\n3450' | passwd kzl

###############################################################################

# zsh
echo 'source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh' | tee -a /root/.zshrc
echo 'source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' | tee -a /root/.zshrc
echo 'source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh' | sudo -u kzl tee -a /home/kzl/.zshrc
echo 'source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' | sudo -u kzl tee -a /home/kzl/.zshrc

# echo 'source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh' | tee -a /etc/zsh/zshrc
# echo 'source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' | tee -a /etc/zsh/zshrc

# locale
sed -i '/^# en_US.UTF-8/s/^#//' /etc/locale.gen
sed -i '/^# zh_CN.UTF-8/s/^#//' /etc/locale.gen
echo 'LANG=en_US.UTF-8' | tee /etc/locale.conf
locale-gen

# environment variables
sudo -u kzl tee /home/kzl/.zshenv << EOF 
typeset -U PATH path
path=("$HOME/.local/bin" "\$path[@]" "/usr/local/sbin" "/usr/sbin" "/sbin")
export PATH
EOF

# time
# timedatectl set-ntp 1

# network
tee /etc/systemd/network/enx.network << EOF
[Match]
Name=enxb827eb27917f

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
