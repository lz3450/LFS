#!/usr/bin/bash
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
  gnome-system-monitor
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
apt-get purge -y \
  apport* \
  avahi* \
  gnome-user-docs \
  ubuntu-docs \
  xserver-xorg* \
  whoopsie
apt-get autoremove --purge -y

dpkg --get-selections | awk '{print $1}' > desktop-installed-pkgs-$(. /etc/os-release && echo $UBUNTU_CODENAME).txt

# disable automount
gsettings set org.gnome.desktop.media-handling automount false

# configure network
mkdir -p /etc/netplan
tee /etc/netplan/00-default.yaml << EOF
network:
  version: 2
  renderer: NetworkManager
EOF
chmod 600 /etc/netplan/00-default.yaml

# configure default target
# systemctl set-default multi-user.target
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
