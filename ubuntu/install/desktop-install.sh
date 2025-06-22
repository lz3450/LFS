#!/bin/bash
#
# desktop-install.sh
#

set -e

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 255
fi

common_deb_pkgs=(
  ### depends
  fonts-dejavu-core
  gdm3
  gnome-shell
  gnome-shell-extension-appindicator
  gnome-shell-extension-desktop-icons-ng
  gnome-shell-extension-ubuntu-dock
  nautilus
  ubuntu-session
  ubuntu-settings
  ### recommends
  fonts-noto-cjk
  fonts-noto-color-emoji
  fonts-ubuntu
  fwupd
  gnome-calculator
  gnome-characters
  # gnome-disk-utility
  gnome-font-viewer
  gnome-logs
  # gnome-power-manager
  gnome-remote-desktop
  gnome-system-monitor
  gnome-terminal
  gsettings-ubuntu-schemas
  seahorse
  ubuntu-wallpapers
  yaru-theme-gnome-shell
  yaru-theme-gtk
  yaru-theme-icon
  yaru-theme-sound
  ### custom
  landscape-client
  tmux
)
jammy_deb_pkgs=(
  ### depends
  fonts-freefont-ttf
  ### recommends
  fonts-opensymbol
  gedit
)
noble_deb_pkgs=(
  # depends
  gnome-shell-extension-ubuntu-tiling-assistant
  # recommends
  # baobab
  fonts-noto-core
  # gnome-clocks
  gnome-text-editor
)
questing_deb_pkgs=(
  ### depends
  gnome-shell-extension-ubuntu-tiling-assistant
  ### recommends
  # baobab
  fonts-noto-core
  # gnome-clocks
  gnome-text-editor
  # papers
)
declare -a deb_pkgs

. /etc/os-release
case "$UBUNTU_CODENAME" in
    jammy)      deb_pkgs=("${common_deb_pkgs[@]}" "${jammy_deb_pkgs[@]}") ;;
    noble)      deb_pkgs=("${common_deb_pkgs[@]}" "${noble_deb_pkgs[@]}") ;;
    questing)   deb_pkgs=("${common_deb_pkgs[@]}" "${questing_deb_pkgs[@]}") ;;
    *)          echo "Unknown suite \"$1\"" && exit 1
esac

# install packages
apt-get update
apt-get upgrade -y
apt-get install --no-install-recommends -s "${deb_pkgs[@]}" | grep "^Inst" | awk '{print $2}' | sort -n > log/$UBUNTU_CODENAME/desktop_to_install_pkgs.txt
apt-get install --no-install-recommends -y "${deb_pkgs[@]}"
apt-get autoremove --purge -y

dpkg --get-selections | awk '{print $1}' | sed -e 's/:amd64//g' > log/$UBUNTU_CODENAME/desktop_installed_pkgs.txt
apt-mark showmanual > log/$UBUNTU_CODENAME/desktop_manual_installed_pkgs.txt

echo "Successfully installed desktop packages for Ubuntu $UBUNTU_CODENAME"
