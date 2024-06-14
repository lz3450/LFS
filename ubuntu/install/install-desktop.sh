#!/bin/bash
#
# install-desktop.sh
#

set -e

apt-get update
apt-get upgrade -y

apt-get install -y ubuntu-desktop-minimal

tee /etc/netplan/00-default.yaml << EOF
network:
  version: 2
  renderer: NetworkManager
EOF

systemctl disable systemd-networkd
systemctl enable NetworkManager
