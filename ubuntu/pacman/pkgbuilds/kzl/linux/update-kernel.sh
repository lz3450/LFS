#!/bin/bash

set -e

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

update-initramfs -k all -c

cp -v initrd.img efi/
cp -v vmlinuz efi/
cp -v initrd.img-@pkgver@-KZL efi/initrd-KZL.img
