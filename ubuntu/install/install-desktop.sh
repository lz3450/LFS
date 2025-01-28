#!/bin/bash
#
# install-desktop.sh
#

set -e

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 255
fi

pkgs=(
  fonts-ubuntu
  gnome-shell-extension-ubuntu-dock
  gnome-shell-extension-ubuntu-tiling-assistant
  gnome-terminal
  gsettings-ubuntu-schemas
  landscape-client
  nautilus
  tmux
  ubuntu-session
  ubuntu-settings
  ubuntu-wallpapers
  yaru-theme-gnome-shell
  yaru-theme-gtk
  yaru-theme-icon
  yaru-theme-sound
)

# install packages
apt-get update
apt-get upgrade -y
apt-get install -s "${pkgs[@]}" | grep "^Inst" | awk '{print $2}' | sort -n > desktop-to-install-pkgs-$(. /etc/os-release && echo $UBUNTU_CODENAME).txt
apt-get install -y "${pkgs[@]}"

# disable automount
gsettings set org.gnome.desktop.media-handling automount false

# cleanup
# if mountpoint -q /var/snap/firefox/common/host-hunspell; then
#     umount /var/snap/firefox/common/host-hunspell
# fi
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
    xserver-xorg* \
    printer-driver-*
apt-get autoremove --purge -y

dpkg --get-selections | awk '{print $1}' > desktop-installed-pkgs-$(. /etc/os-release && echo $UBUNTU_CODENAME).txt

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
rm -vrf /usr/lib/xorg/modules

# configure network
mkdir -p /etc/netplan
tee /etc/netplan/00-default.yaml << EOF
network:
  version: 2
  renderer: NetworkManager
EOF
chmod 600 /etc/netplan/00-default.yaml
systemctl disable systemd-networkd
systemctl disable wpa_supplicant@
systemctl enable NetworkManager

# configure default target
systemctl set-default multi-user.target
case "$(. /etc/os-release && echo $UBUNTU_CODENAME)" in
    noble)
        systemctl set-default graphical.target
        ;;
    jammy)
        systemctl set-default graphics.target
        ;;
    *)
        echo "Not supported codename"
        ;;
esac
