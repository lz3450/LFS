#!/bin/bash
#
# install-clean.sh
#

sudo apt-get purge -y \
    ubuntu-advantage-tools \
    ubuntu-drivers-common \
    ubuntu-docs \
    ubuntu-release-upgrader-core \
    ubuntu-report \
    apport \
    sssd \
    avahi-daemon

sudo apt-get purge -y memtest86+ || :

if mountpoint -q /var/snap/firefox/common/host-hunspell; then
    sudo umount /var/snap/firefox/common/host-hunspell
fi
sudo apt-get purge -y snapd
sudo rm -vf "/etc/systemd/system/var-snap-firefox-common-host\\x2dhunspell.mount"
sudo rm -vrf /etc/systemd/system/snapd.mounts.target.wants

sudo apt-get autoremove --purge

sudo rm -vrf /var/lib/update-manager
sudo rm -vrf /var/lib/update-notifier
sudo rm -vrf /var/lib/ubuntu-release-upgrader
sudo rm -vrf /var/log/unattended-upgrades

# sudo systemctl set-default multi-user.target
# sudo systemctl set-default graphics.target
