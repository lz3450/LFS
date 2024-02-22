#!/bin/bash

set -e -u

debootstrap --arch="amd64" jammy /mnt http://us.archive.ubuntu.com/ubuntu

for fs in dev sys proc run; do
    mount --rbind /$fs /mnt/$fs
    mount --make-rslave /mnt/$fs
done

fallocate -l 16G /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile

cp initialize.sh /mnt/root
LANG=C.UTF-8 PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin chroot /mnt /bin/bash

# boot
# EFI: /boot/efi
blkid >> /mnt/boot/efi/loader/entries/ubuntu.conf
nano /mnt/boot/efi/loader/entries/ubuntu.conf

# fstab
if [ -f "/usr/bin/genfstab" ]; then
    genfstab -t PARTUUID /mnt > /mnt/etc/fstab
else
    blkid > /mnt/etc/fstab
fi
nano /mnt/etc/fstab
