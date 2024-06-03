#!/usr/bin/bash

session_number=$(loginctl list-sessions | awk '$5 == "tty2" {print $1}')
loginctl unlock-session "$session_number"

# pkill -f -u kzl gnome-keyring-daemon
read -r -s -p "Enter password: " password
echo
echo -n "$password" | gnome-keyring-daemon -r -d --unlock
systemctl --user restart gnome-remote-desktop.service
