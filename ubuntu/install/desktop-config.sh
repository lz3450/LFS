#!/bin/bash
#
# desktop-config.sh
#

set -e

# disable automount
gsettings set org.gnome.desktop.media-handling automount false

# configure network
# mkdir -p /etc/netplan
# tee /etc/netplan/00-default.yaml << EOF
# network:
#   version: 2
#   renderer: NetworkManager
# EOF
# chmod 600 /etc/netplan/00-default.yaml

# configure default target
# systemctl set-default multi-user.target
# systemctl set-default graphical.target
