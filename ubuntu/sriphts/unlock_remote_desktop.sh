#!/usr/bin/bash

pkill -f -u kzl gnome-keyring-daemon
echo -n 'skzlj999' | gnome-keyring-daemon --unlock
systemctl --user restart gnome-remote-desktop.service
