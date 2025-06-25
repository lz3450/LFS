#!/bin/bash
#
# 12-install-desktop.sh
#

set -e

if (( EUID < 1000 )); then
    echo "This script should be run as user"
    exit 255
fi

gsettings set org.gnome.desktop.media-handling automount false
