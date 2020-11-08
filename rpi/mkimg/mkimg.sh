#!/bin/bash

set -e

IMG="/tmp/raspi.img"
MOUNTPOINT="/tmp/raspi"

if [ -f $IMG ]; then
    rm $IMG
fi

fallocate -l 2G $IMG

parted -s $IMG \
    mktable msdos \
    unit s \
    mkpart primary fat32 1s 262143s \
    mkpart primary ext4 262144s 100% \
    set 2 lba off \
    print

sudo umount -R $MOUNTPOINT || :
sudo losetup -D
loop=$(sudo losetup -f)
echo "Loop device is \"$loop\""

sudo losetup -P $loop $IMG

sudo mkfs.fat -F32 ${loop}p1
sudo mkfs.ext4 ${loop}p2

sudo mkdir -p $MOUNTPOINT
sudo mount ${loop}p2 $MOUNTPOINT
sudo mkdir -p $MOUNTPOINT/boot
sudo mount ${loop}p1 $MOUNTPOINT/boot

sudo debootstrap --arch=arm64 testing $MOUNTPOINT http://deb.debian.org/debian
echo "RPi" | sudo tee $MOUNTPOINT/etc/hostname
sudo cp -f fstab $MOUNTPOINT/etc/
sudo cp -f sources.list $MOUNTPOINT/etc/apt/
sudo cp -f raspi.list $MOUNTPOINT/etc/apt/sources.list.d/
sudo cp -f cmdline.txt $MOUNTPOINT/boot/
sudo cp -f config.txt $MOUNTPOINT/boot/

bootpartuuid=$(sudo blkid -s PARTUUID | grep ${loop}p1 | sed -e 's#.*=\"\(.*\)\"#\1#')
rootpartuuid=$(sudo blkid -s PARTUUID | grep ${loop}p2 | sed -e 's#.*=\"\(.*\)\"#\1#')
sudo sed -e "s|%BOOTPARTUUID%|$bootpartuuid|" -i $MOUNTPOINT/etc/fstab
sudo sed -e "s|%ROOTPARTUUID%|$rootpartuuid|" -i $MOUNTPOINT/etc/fstab
sudo sed -e "s|%ROOTPARTUUID%|$rootpartuuid|" -i $MOUNTPOINT/boot/cmdline.txt

sudo tee -a $MOUNTPOINT/etc/hosts << EOF
$(ping -c1 deb.debian.org| head -1 | cut -d '(' -f3 | cut -d ')' -f1)           deb.debian.org
$(ping -c1 archive.raspberrypi.org| head -1 | cut -d '(' -f3 | cut -d ')' -f1)  archive.raspberrypi.org
$(ping -c1 deb.grml.org| head -1 | cut -d '(' -f3 | cut -d ')' -f1)             deb.grml.org
EOF

sudo cp initialize.sh $MOUNTPOINT/root

LC_ALL=C PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin sudo chroot $MOUNTPOINT /bin/bash -c "/root/initialize.sh"

sudo rm $MOUNTPOINT/root/initialize.sh

sudo umount -R $MOUNTPOINT
sudo losetup -D
