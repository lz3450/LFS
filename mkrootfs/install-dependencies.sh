#!/usr/bin/bash

sudo apt-get update
sudo apt-get install -y \
    binfmt-support \
    dosfstools \
    isomd5sum \
    qemu-user-static \
    xorriso
sudo pacman -Sy --noconfirm \
    debootstrap \
    dracut \
    erofs-utils
