#!/usr/bin/env bash
#
# pacman-repo-setup.sh
#

set -e

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 255
fi

cp -vf pacman-repo /etc/nginx/sites-available/pacman-repo
ln -vrsf /etc/nginx/sites-available/pacman-repo /etc/nginx/sites-enabled/

systemctl reload nginx
