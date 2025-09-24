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

### /tmp
systemctl enable --now /usr/share/systemd/tmp.mount

### network-manager
if [[ "$UBUNTU_CODENAME" == "jammy" ]]; then
    tee /etc/netplan/00-default.yaml << EOF
network:
  version: 2
  renderer: NetworkManager
EOF
    chmod 600 /etc/netplan/00-default.yaml
    netplan apply
    systemctl disable wpa_supplicant@wlan0.service
    systemctl disable systemd-networkd.service
    systemctl enable wpa_supplicant.service
    systemctl enable NetworkManager.service
    nmtui
else
    echo "Unsupported Ubuntu suite: $UBUNTU_CODENAME"
    exit 1
fi

echo "Successfully configured system settings for Ubuntu $UBUNTU_CODENAME"
