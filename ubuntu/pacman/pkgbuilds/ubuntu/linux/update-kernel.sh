#!/bin/bash
#
# update-kernel.sh
#

set -e

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

if [[ -n "$BASH_VERSION" ]]; then
  export BOOT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1; pwd -P)"
elif [[ -n "$ZSH_VERSION" ]]; then
  export BOOT_DIR="$(cd -- "$(dirname "${(%):-%x}")" > /dev/null 2>&1; pwd -P)"
else
  echo "Unsupported shell"
fi

update-initramfs -k all -c

cp -v "$BOOT_DIR"/initrd.img "$BOOT_DIR"/efi/
cp -v "$BOOT_DIR"/vmlinuz "$BOOT_DIR"/efi/
cp -v "$BOOT_DIR"/initrd.img-@pkgver@-KZL "$BOOT_DIR"/efi/initrd-KZL.img
cp -v "$BOOT_DIR"/vmlinuz-6.12.11-KZL "$BOOT_DIR"/efi/vmlinuz-KZL
