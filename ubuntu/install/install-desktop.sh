#!/bin/bash
#
# install-desktop.sh
#

set -e

sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install -y ubuntu-desktop-minimal

cat > /etc/netplan/00-default.yaml << EOF
network:
  version: 2
  renderer: NetworkManager
EOF

sudo systemctl disable systemd-networkd
sudo systemctl enable NetworkManager
