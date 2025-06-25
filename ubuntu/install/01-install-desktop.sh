#!/bin/bash
#
# 01-install-desktop.sh
#

set -e

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 255
fi

. /etc/os-release
LOG_DIR="log/$UBUNTU_CODENAME"
TO_INSTALL_PKGLIST_FILE="$LOG_DIR/desktop_to_install_pkgs.txt"
INSTALLED_PKGLIST_FILE="$LOG_DIR/desktop_installed_pkgs.txt"
MANUAL_INSTALLED_PKGLIST_FILE="$LOG_DIR/desktop_manual_installed_pkgs.txt"

common_deb_pkgs=(
  ### ubuntu-minimal-desktop depends
  gdm3
  gnome-control-center
  gnome-menus
  gnome-session-canberra
  gnome-shell-extension-appindicator
  gnome-shell-extension-desktop-icons-ng
  gnome-shell-extension-ubuntu-dock
  ubuntu-session
  ubuntu-settings
  ### gnome
  eog
  gnome-calculator
  gnome-power-manager
  gnome-system-monitor
  gnome-terminal
  seahorse
  ### ubuntu
  gsettings-ubuntu-schemas
  yaru-theme-gtk
  yaru-theme-icon
  yaru-theme-sound
  ### network
  network-manager
  network-manager-config-connectivity-ubuntu
  rfkill
  ### sound
  alsa-base
  alsa-utils
  ### fonts
  fonts-ubuntu
  ### utils
  file
  fwupd
  pciutils
  psmisc
  usbutils
)
jammy_deb_pkgs=(
  ### gnome
  evince
  gedit
  gnome-bluetooth
  gnome-startup-applications
  ### network
  network-manager-gnome
)
noble_deb_pkgs=(
)
questing_deb_pkgs=(
  ### ubuntu-minimal-desktop depends
  gnome-shell-extension-ubuntu-tiling-assistant
  ### gnome
  gnome-bluetooth-sendto
  gnome-remote-desktop
  gnome-text-editor
  papers
  ### network
  nm-connection-editor
)
deb_pkgs=()

case "$UBUNTU_CODENAME" in
    jammy)      deb_pkgs=("${common_deb_pkgs[@]}" "${jammy_deb_pkgs[@]}") ;;
    noble)      deb_pkgs=("${common_deb_pkgs[@]}" "${noble_deb_pkgs[@]}") ;;
    questing)   deb_pkgs=("${common_deb_pkgs[@]}" "${questing_deb_pkgs[@]}") ;;
    *)          echo "Unknown suite \"$1\"" && exit 1
esac

# log files
mkdir -vp -- "$LOG_DIR"
touch -- "$TO_INSTALL_PKGLIST_FILE" "$INSTALLED_PKGLIST_FILE" "$MANUAL_INSTALLED_PKGLIST_FILE"
chown -R ${SUDO_UID:-0}:${SUDO_GID:-0} -- "$LOG_DIR"

# install packages
apt-get update
apt-get upgrade -y
apt-get install --no-install-recommends -s "${deb_pkgs[@]}" | grep "^Inst" | awk '{print $2}' | LC_ALL=C sort -n > "$TO_INSTALL_PKGLIST_FILE"
apt-get install --no-install-recommends -y "${deb_pkgs[@]}"
apt-get autoremove --purge -y
dpkg --get-selections | awk '{print $1}' | sed -e 's/:amd64//g' > "$INSTALLED_PKGLIST_FILE"
apt-mark showmanual > "$MANUAL_INSTALLED_PKGLIST_FILE"

echo "Successfully installed desktop packages for Ubuntu $UBUNTU_CODENAME"
