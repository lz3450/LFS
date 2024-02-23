#!/bin/bash
#
# install-desktop.sh
#

set -e

sudo apt update
sudo apt upgrade -y

sudo apt install -y ubuntu-desktop-minimal

sudo apt purge -y \
    ubuntu-advantage-tools \
    ubuntu-drivers-common \
    ubuntu-docs \
    ubuntu-release-upgrader-core \
    ubuntu-report \
    sssd \
    avahi-daemon \
    memtest86+

sudo rm -vrf /var/lib/update-manager
sudo rm -vrf /var/lib/update-notifier
sudo rm -vrf /var/lib/ubuntu-release-upgrader

if mountpoint -q /var/snap/firefox/common/host-hunspell; then
    sudo umount /var/snap/firefox/common/host-hunspell
fi
sudo apt purge -y snapd
sudo rm -vf "/etc/systemd/system/var-snap-firefox-common-host\\x2dhunspell.mount"
sudo rm -vrf /etc/systemd/system/snapd.mounts.target.wants

sudo apt autoremove --purge
sudo rm -vrf /var/log/unattended-upgrades

sudo systemctl set-default multi-user.target
