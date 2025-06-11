#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

update-initramfs -c -k all

for kernel_version in $(ls /usr/lib/modules); do
    kv=$(echo "$kernel_version" | sed -e 's#.*[0-9]\.[0-9]\.[0-9]\+\(-v\)\?\(.*\)+#\2#')
    case "$kv" in
        8-16k)
            kv="_2712"
            ;;
    esac
    cp -dr "/boot/initrd.img-$kernel_version" "/boot/firmware/initramfs$kv"
done
