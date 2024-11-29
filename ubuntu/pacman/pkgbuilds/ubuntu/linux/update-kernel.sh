#!/bin/bash

set -e

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

if [ -n "$BASH_VERSION" ]; then
  export ROOTDIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1; pwd -P)"
elif [ -n "$ZSH_VERSION" ]; then
  export ROOTDIR="$(cd -- "$(dirname "${(%):-%x}")" >/dev/null 2>&1; pwd -P)"
else
  echo "Unsupported shell"
fi

update-initramfs -k all -c

cp -v "$ROOTDIR"/initrd.img "$ROOTDIR"/efi/
cp -v "$ROOTDIR"/vmlinuz "$ROOTDIR"/efi/
cp -v "$ROOTDIR"/initrd.img-@pkgver@-KZL "$ROOTDIR"/efi/initrd-KZL.img
