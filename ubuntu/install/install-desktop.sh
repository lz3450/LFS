#!/bin/bash
#
# install-desktop.sh
#

sudo apt update
sudo apt upgrade -y

sudo apt install -y ubuntu-desktop-minimal

sudo apt purge -y \
    ubuntu-advantage-tools \
    ubuntu-drivers-common \
    ubuntu-docs \
    ubuntu-release-upgrader-core \
    ubuntu-report

sudo rm -rf /var/lib/update-manager
sudo rm -rf /var/lib/update-notifier
sudo rm -rf /var/lib/ubuntu-release-upgrader

# sudo umount /var/snap/firefox/common/host-hunspell
sudo apt purge -y snapd
# sudo rm -f "/etc/systemd/system/var-snap-firefox-common-host\\x2dhunspell.mount"
# sudo rm -rf /etc/systemd/system/snapd.mounts.target.wants

sudo apt autoremove --purge
sudo rm -rf /var/log/unattended-upgrades

sudo systemctl set-default multi-user.target
