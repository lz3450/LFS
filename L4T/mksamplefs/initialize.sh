#!/bin/bash

# user
echo -e '3450\n3450' | passwd root
# useradd -m -U -G sudo -s /bin/zsh kzl
# echo -e '3450\n3450' | passwd kzl

###############################################################################

# zsh
wget -O grml-etc-core.deb http://deb.grml.org/pool/main/g/grml-etc-core/grml-etc-core_0.18.0_all.deb || :
wget -O zsh-autosuggestions.deb http://ports.ubuntu.com/ubuntu-ports/pool/universe/z/zsh-autosuggestions/zsh-autosuggestions_0.6.4-1_all.deb
dpkg -i grml-etc-core.deb || :
dpkg -i zsh-autosuggestions.deb || :
rm grml-etc-core.deb || :
rm zsh-autosuggestions.deb || :

echo 'source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh' | tee -a /etc/zsh/zshrc
echo 'source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' | tee -a /etc/zsh/zshrc

# # locale
# sed -i '/^# en_US.UTF-8/s/^#//' /etc/locale.gen
# # sed -i '/^# zh_CN.UTF-8/s/^#//' /etc/locale.gen
# echo 'LANG=en_US.UTF-8' | tee -a /etc/locale.conf
# locale-gen

# # environment variables
# sudo -u kzl tee -a /home/kzl/.zshenv << EOF 
# typeset -U PATH path
# path=("$HOME/.local/bin" "\$path[@]")
# export PATH
# EOF

sudo rm -rf /etc/environment
sudo touch /etc/environment

# # time
# timedatectl set-ntp 1

# # network
# tee /etc/systemd/network/eth0.network << EOF
# [Match]
# Name=eth0

# [Network]
# DHCP=yes
# EOF
# tee /etc/systemd/network/wlan0.network << EOF
# [Match]
# Name=wlan0

# [Network]
# DHCP=yes
# EOF
# tee /etc/wpa_supplicant/wpa_supplicant-wlan0.conf << EOF
# network={
#         ssid="LuckySKZLJ"
#         psk=a8ba39d6dc7bc6e4984dcc45a386719fe42b5876dc4fd56c516a521615ee981c
# }
# EOF

# systemctl enable systemd-networkd systemd-resolved wpa_supplicant@wlan0 ssh
# ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf