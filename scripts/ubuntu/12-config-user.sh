#!/bin/bash
#
# 12-config-user.sh
#

set -e

if (( EUID < 1000 )); then
    echo "This script should be run as user"
    exit 255
fi

gsettings set org.gnome.desktop.media-handling automount false

echo "Successfully configured user settings for Ubuntu $UBUNTU_CODENAME"
