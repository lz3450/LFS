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
  alsa-base
  alsa-utils
  bc
  file
  file-roller
  fonts-dejavu-core
  fonts-freefont-ttf
  fonts-noto-cjk
  fonts-noto-color-emoji
  fonts-ubuntu
  gdm3
  gnome-bluetooth
  gnome-calculator
  gnome-control-center
  gnome-menus
  gnome-power-manager
  gnome-remote-desktop
  gnome-session-canberra
  gnome-shell-extension-appindicator
  gnome-shell-extension-desktop-icons-ng
  gnome-shell-extension-ubuntu-dock
  gnome-system-monitor
  gnome-terminal
  network-manager-config-connectivity-ubuntu
  pciutils
  power-profiles-daemon
  psmisc
  pulseaudio
  rfkill
  seahorse
  ubuntu-session
  ubuntu-settings
  usbutils
  xdg-user-dirs-gtk
  xdg-utils
  yaru-theme-gtk
  yaru-theme-icon
  yaru-theme-sound
)
jammy_deb_pkgs=(
  eog
  evince
  nautilus-extension-gnome-terminal
  gnome-text-editor
)
noble_deb_pkgs=(
  eog
  evince
  nautilus-extension-gnome-terminal
  gnome-text-editor
)
# TODO: not checked
resolute_deb_pkgs=(
  ### ubuntu-minimal-desktop depends
  gnome-shell-extension-ubuntu-tiling-assistant
  ### gnome
  gnome-bluetooth-sendto
  papers
  ### network
  nm-connection-editor
)
# TODO: prompt for installing
recommended_deb_pkgs=(
  fwupd
)
deb_pkgs=()

case "$UBUNTU_CODENAME" in
    jammy)      deb_pkgs=("${common_deb_pkgs[@]}" "${jammy_deb_pkgs[@]}") ;;
    noble)      deb_pkgs=("${common_deb_pkgs[@]}" "${noble_deb_pkgs[@]}") ;;
    resolute)   deb_pkgs=("${common_deb_pkgs[@]}" "${resolute_deb_pkgs[@]}") ;;
    *)          echo "Unknown suite \"$1\"" && exit 1
esac

# log files
mkdir -vp -- "$LOG_DIR"
touch -- "$TO_INSTALL_PKGLIST_FILE" "$INSTALLED_PKGLIST_FILE" "$MANUAL_INSTALLED_PKGLIST_FILE"

# install packages
apt-get update
apt-get upgrade -y
apt-get install --no-install-recommends -s "${deb_pkgs[@]}" | grep "^Inst" | awk '{print $2}' | LC_ALL=C sort -n > "$TO_INSTALL_PKGLIST_FILE"
apt-get install --no-install-recommends -y "${deb_pkgs[@]}"
apt-get autoremove --purge -y
dpkg --get-selections | awk '{print $1}' | sed -e 's/:amd64//g' -e 's/:arm64//g' > "$INSTALLED_PKGLIST_FILE"
apt-mark showmanual > "$MANUAL_INSTALLED_PKGLIST_FILE"

chown -R ${SUDO_UID:-0}:${SUDO_GID:-0} -- "$LOG_DIR"
echo "Successfully installed desktop packages for Ubuntu $UBUNTU_CODENAME"
