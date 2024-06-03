#!/bin/bash
#
# install-clean.sh
#

if mountpoint -q /var/snap/firefox/common/host-hunspell; then
    sudo umount /var/snap/firefox/common/host-hunspell
fi

sudo apt-get purge -y \
    ubuntu-advantage-* \
    ubuntu-drivers-* \
    ubuntu-docs \
    ubuntu-release-upgrader-* \
    ubuntu-report \
    ubuntu-pro-* \
    apport \
    sssd \
    avahi-daemon \
    memtest86+ \
    snapd \
    xserver-xorg \
    printer-driver-*
sudo apt-get autoremove --purge

sudo rm -vrf /var/lib/update-manager
sudo rm -vrf /var/lib/ubuntu-drivers-common
sudo rm -vrf /var/lib/update-notifier
sudo rm -vrf /var/lib/ubuntu-release-upgrader
sudo rm -vrf /etc/systemd/system/snapd.mounts.target.wants
sudo rm -vf "/etc/systemd/system/var-snap-firefox-common-host\\x2dhunspell.mount"
sudo rm -vrf /usr/share/hplip
sudo rm -vrf /usr/share/fonts/X11/Type1
sudo rm -vrf /usr/share/X11/xorg.conf.d
sudo rm -vrf /usr/lib/xorg/modules/extensions
sudo rm -vrf /usr/lib/xorg/modules/drivers
sudo rmdir -v /usr/lib/xorg/modules

# sudo systemctl set-default multi-user.target
# sudo systemctl set-default graphics.target
