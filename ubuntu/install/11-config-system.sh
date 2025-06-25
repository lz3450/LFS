#!/bin/bash
#
# 11-config-system.sh
#

set -e

if (( EUID != 0 )); then
    echo "This script must be run as root"
    exit 255
fi

. /etc/os-release

# disable automount

if [[ "$UBUNTU_CODENAME" == "jammy" ]]; then
    tee /etc/netplan/00-default.yaml << EOF
network:
  version: 2
  renderer: NetworkManager
EOF
    chmod 600 /etc/netplan/00-default.yaml
    netplan apply
    systemctl disable --now systemd-networkd.service
    systemctl disable --now systemd-resolved.service
    systemctl restart NetworkManager.service
elif [[ "$UBUNTU_CODENAME" == "noble" ]]; then
    :
elif [[ "$UBUNTU_CODENAME" == "questing" ]]; then
    :
else
    echo "Unsupported Ubuntu suite: $UBUNTU_CODENAME"
    exit 1
fi
