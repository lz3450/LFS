#! /usr/bin/bash

if [ ! -d ~/.config/i3status/ ]; then
    mkdir -p ~/.config/i3status/
fi

cp -f config ~/.config/i3status/config
