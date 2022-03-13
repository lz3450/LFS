#! /bin/sh

# EFI: /boot/efi

for fs in dev sys proc run; do
    mount --rbind /$fs /mnt/$fs
    mount --make-rslave /mnt/$fs
done

debootstrap jammy /mnt http://us.archive.ubuntu.com/ubuntu

cp initialize.sh /mnt/root
genfstab -U /mnt > /mnt/etc/fstab

LANG=C.UTF-8 PATH=/usr/bin:/usr/sbin chroot /mnt /bin/bash
