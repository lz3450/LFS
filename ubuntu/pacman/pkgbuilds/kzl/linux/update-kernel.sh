#!/bin/bash

set -e

sudo update-initramfs -k all -c

sudo cp -v initrd.img efi/
sudo cp -v vmlinuz efi/
sudo cp -v initrd.img-@pkgver@-KZL efi/initrd-KZL.img
