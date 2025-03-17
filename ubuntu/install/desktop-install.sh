#!/usr/bin/bash
#
# install-desktop.sh
#

set -e

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 255
fi

common_deb_pkgs=(
  fonts-ubuntu
  gnome-shell-extension-ubuntu-dock
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
noble_deb_pkgs=(
  gnome-shell-extension-ubuntu-tiling-assistant
)
declare -a deb_pkgs

. /etc/os-release
case "$UBUNTU_CODENAME" in
    jammy)      deb_pkgs=("${common_deb_pkgs[@]}") ;;
    noble)      deb_pkgs=("${common_deb_pkgs[@]}" "${noble_deb_pkgs[@]}") ;;
    *)          echo "Unknown suite \"$1\"" && exit 1
esac

# install packages
apt-get update
apt-get upgrade -y
apt-get install -s "${deb_pkgs[@]}" | grep "^Inst" | awk '{print $2}' | sort -n > desktop-to-install-pkgs-$UBUNTU_CODENAME.txt
apt-get install -y "${deb_pkgs[@]}"
apt-get purge -y \
  apport* \
  avahi* \
  gnome-user-docs \
  ubuntu-docs \
  xserver-xorg* \
  whoopsie
apt-get autoremove --purge -y

dpkg --get-selections | awk '{print $1}' | sed -e 's/:amd64//g' > desktop-installed-pkgs-$UBUNTU_CODENAME.txt
apt-mark showmanual > desktop-manual-installed-pkgs-$UBUNTU_CODENAME.txt
