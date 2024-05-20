#!/usr/bin/bash

# pkill -f -u kzl gnome-keyring-daemon
read -r -s -p "Enter password: " password
echo
echo -n "$password" | gnome-keyring-daemon -r -d --unlock
systemctl --user restart gnome-remote-desktop.service
