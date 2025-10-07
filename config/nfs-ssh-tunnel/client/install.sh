#! /usr/bin/env bash

set -e

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" >&2
    exit 1
fi

cp home-kzl-Projects.mount /etc/systemd/system/home-kzl-Projects.mount
cp home-kzl-Projects.automount /etc/systemd/system/home-kzl-Projects.automount
cp home-kzl-Projects-umount.service /etc/systemd/system/home-kzl-Projects-umount.service

systemctl daemon-reload
systemctl enable home-kzl-Projects.automount
systemctl enable home-kzl-Projects-umount.service
systemctl start home-kzl-Projects.automount
