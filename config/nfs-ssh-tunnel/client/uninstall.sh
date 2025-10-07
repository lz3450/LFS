#! /usr/bin/env bash

set -e

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" >&2
    exit 1
fi

rm -v /etc/systemd/system/home-kzl-Projects.mount
rm -v /etc/systemd/system/home-kzl-Projects.automount

systemctl daemon-reload
systemctl disable home-kzl-Projects.automount || :
systemctl stop home-kzl-Projects.automount || :
