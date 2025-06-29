#!/usr/bin/bash

sudo apt-get update
sudo apt-get install -y \
    dosfstools \
    isomd5sum \
    xorriso
sudo pacman -Sy --noconfirm \
    dracut \
    erofs-utils \
    f2fs-tools