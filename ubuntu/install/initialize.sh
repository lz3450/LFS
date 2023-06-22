#! /bin/sh

set -e -u

apt update

apt install -y \
    zsh \
    wget curl \
    nano \
    zsh-autosuggestions \
    zsh-syntax-highlighting

dpkg-reconfigure locales
dpkg-reconfigure tzdata

read -p 'hostname: ' HOSTNAME
echo $HOSTNAME > /etc/hostname

bootctl install --esp-path=/boot/efi

# passwd
echo "root password:"
passwd

useradd -m -U -G sudo -s /bin/zsh kzl
echo "kzl password:"
passwd kzl

# network
cat > /etc/systemd/network/ethernet.network << EOF
[Match]
Name=en*
Name=eth*

[Network]
DHCP=yes
EOF

cat > /etc/netplan/network.yaml << EOF
network:
  version: 2
  renderer: NetworkManager
EOF
