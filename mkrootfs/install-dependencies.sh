#!/bin/bash

sudo apt-get update
sudo apt-get install -y \
    qemu-user-static
sudo pacman -Syu --noconfirm \
    debootstrap

