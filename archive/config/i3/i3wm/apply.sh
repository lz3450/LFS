#! /usr/bin/bash

if [ ! -d ~/.config/i3/ ]; then
    mkdir -p ~/.config/i3/
fi

cp -f config ~/.config/i3/config
