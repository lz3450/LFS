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
  ### ubuntu-desktop-minimal depends
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
  wireless-tools
  wpasupplicant
  xdg-user-dirs
  xdg-user-dirs-gtk
  ### ubuntu-desktop-minimal recommends
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
  fdisk parted
  ### recommends
  nautilus-extension-gnome-terminal
  ### other
  bash-completion
  zsh zsh-syntax-highlighting zsh-autosuggestions
  nano
  openssh-server
  wget
)
nvidia_l4t_deps=(
  ### flash
  bridge-utils
  cpio
  mtd-utils
  oem-config-gtk
  ubiquity-frontend-debconf ubiquity-frontend-gtk
  plymouth
  zstd
  ### nvidia-l4t-* depends
  debconf-utils
  device-tree-compiler
  efibootmgr
  gir1.2-appindicator3-0.1
  iputils-ping
  libegl1-mesa
  libffi7
  libgstreamer-plugins-bad1.0-0
  libnl-3-200
  libnl-genl-3-200
  libnl-route-3-200
  libseat1
  libvulkan1
  libvulkan1
  net-tools
  nvme-cli
  python2
  python3-matplotlib
  python3-tk
  xorg
)
pkgs_to_remove=(
  # libnetplan0
  # netplan.io
)

# install packages
apt-get update
apt-get upgrade -y
apt-get install --no-install-recommends -y "${deb_pkgs[@]}"
apt-get install --no-install-recommends -y "${nvidia_l4t_deps[@]}"
# apt-get remove --purge -y "${pkgs_to_remove[@]}"
apt-get autoremove --purge -y
apt-mark auto "${nvidia_l4t_deps[@]}"
apt-mark showmanual > manual_installed_pkgs.txt

echo "root:root" | chpasswd

echo "Successfully installed desktop packages for Ubuntu $UBUNTU_CODENAME"

dpkg -l | awk '{print $2}'
