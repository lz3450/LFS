#!/bin/bash
#
# install.sh
#

debootstrap_suite="jammy"

set -e

debootstrap --arch="amd64" "$debootstrap_suite" /mnt http://us.archive.ubuntu.com/ubuntu

fallocate -l 16G /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile

cp initialize.sh /mnt/root

for fs in dev sys proc run; do
    mount --rbind /$fs /mnt/$fs
    mount --make-rslave /mnt/$fs
done
LANG=C.UTF-8 PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin chroot /mnt /bin/bash
for fs in dev sys proc run; do
    umount -R "$debootstrap_dir"/$fs
done

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
