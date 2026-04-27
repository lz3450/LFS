#!/usr/bin/env bash
#
# l4t/initialize.sh
#

set -e

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 255
fi

deb_pkgs=(
  ### ubuntu-minimal-desktop depends
  alsa-base
  alsa-utils
  bc
  ca-certificates
  fonts-dejavu-core
  fonts-freefont-ttf
  gdm3
  gnome-control-center
  gnome-menus
  gnome-session-canberra
  gnome-settings-daemon
  gnome-shell
  gnome-shell-extension-appindicator
  gnome-shell-extension-desktop-icons-ng
  gnome-shell-extension-ubuntu-dock
  nautilus
  pulseaudio
  rfkill
  ubuntu-session
  ubuntu-settings
  xdg-user-dirs
  xdg-user-dirs-gtk
  ### ubuntu-minimal-desktop recommends
  file-roller
  fonts-noto-cjk
  fonts-noto-color-emoji
  fonts-ubuntu
  gnome-bluetooth
  gnome-calculator
  gnome-keyring
  gnome-power-manager
  gnome-remote-desktop
  gnome-system-monitor
  gnome-terminal
  network-manager
  network-manager-config-connectivity-ubuntu
  seahorse
  ubuntu-wallpapers
  xdg-utils
  yaru-theme-gnome-shell
  yaru-theme-gtk
  yaru-theme-icon
  yaru-theme-sound
  ### power
  power-profiles-daemon
  ### utils
  file
  pciutils
  psmisc
  usbutils
  ###
  eog
  evince
  nautilus-extension-gnome-terminal
  gnome-text-editor
  ### l4t
  bridge-utils
  cpio
  debconf-utils
  oem-config-debconf
  oem-config-gtk
  mtd-utils
  zstd
  ### other
  build-essential
  bash-completion
  zsh zsh-syntax-highlighting zsh-autosuggestions
  nano
  openssh-server
  curl wget git
  tmux
  python3-pip python3-setuptools
)

# install packages
apt-get update
apt-get upgrade -y
apt-get install --no-install-recommends -y "${deb_pkgs[@]}"
apt-get autoremove --purge -y
apt-mark showmanual > manual_installed_pkgs.txt

echo "Successfully installed desktop packages for Ubuntu $UBUNTU_CODENAME"
