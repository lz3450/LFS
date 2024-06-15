#!/bin/bash
#
# install-desktop.sh
#

set -e

apt-get update
apt-get upgrade -y

pkgs=(
  ubuntu-desktop-minimal
  tmux
  landscape-client
)

apt-get install -s "${pkgs[@]}" | grep "^Inst" | awk '{print $2}' | sort > configuration-pkgs.txt
apt-get install -y "${pkgs[@]}"

mkdir -p /etc/netplan
tee /etc/netplan/00-default.yaml << EOF
network:
  version: 2
  renderer: NetworkManager
EOF

if mountpoint -q /var/snap/firefox/common/host-hunspell; then
    umount /var/snap/firefox/common/host-hunspell
fi

# cleanup
apt-get purge -y \
    ubuntu-advantage-* \
    ubuntu-drivers-* \
    ubuntu-docs \
    ubuntu-release-upgrader-* \
    ubuntu-report \
    ubuntu-pro-* \
    apport \
    sssd \
    avahi-daemon \
    memtest86+* \
    snapd \
    xserver-xorg \
    printer-driver-*
apt-get autoremove --purge -y

rm -vrf /var/lib/update-manager
rm -vrf /var/lib/ubuntu-drivers-common
rm -vrf /var/lib/update-notifier
rm -vrf /var/lib/ubuntu-release-upgrader
rm -vrf /etc/systemd/system/snapd.mounts.target.wants
rm -vf "/etc/systemd/system/var-snap-firefox-common-host\\x2dhunspell.mount"
rm -vrf /usr/share/hplip
rm -vrf /usr/share/fonts/X11/Type1
rm -vrf /usr/share/X11/xorg.conf.d
rm -vrf /usr/lib/xorg/modules/extensions
rm -vrf /usr/lib/xorg/modules/drivers
rmdir -v /usr/lib/xorg/modules

systemctl disable systemd-networkd
systemctl enable NetworkManager
# systemctl set-default multi-user.target
# systemctl set-default graphics.target
