#!/bin/bash
#
# mkimg.sh
#

set -e
# set -x

script_name="$(basename "${0}")"
script_path="$(readlink -f "${0}")"
script_dir="$(dirname "${script_path}")"
img="/tmp/raspi.img"
mountpoint="/tmp/raspi"
chroot_path="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"

create_img() {
    fallocate -l 2G ${img}

    parted -s ${img} \
        mktable msdos \
        unit s \
        mkpart primary fat32 1s 524287s \
        mkpart primary ext4 524288s 100% \
        set 2 lba off \
        print

    loop=$(sudo losetup -f)
    echo "Loop device is \"$loop\""

    sudo losetup -P ${loop} ${img}

    sudo mkfs.fat -F32 ${loop}p1
    sudo mkfs.ext4 ${loop}p2

    sudo mkdir -p ${mountpoint}
    sudo mount ${loop}p2 ${mountpoint}
    sudo mkdir -p ${mountpoint}/boot
    sudo mount ${loop}p1 ${mountpoint}/boot
}

configure_img() {
    # debootstrap
    sudo debootstrap --arch=arm64 --foreign buster ${mountpoint} http://ftp.debian.org/debian
    # sudo cp /usr/bin/qemu-aarch64-static ${mountpoint}/usr/bin
    sudo LC_ALL=C PATH="${chroot_path}" chroot ${mountpoint} /debootstrap/debootstrap --second-stage

    echo "RPi" | sudo tee ${mountpoint}/etc/hostname
    sudo cp -f fstab ${mountpoint}/etc/
    sudo cp -f sources.list ${mountpoint}/etc/apt/
    sudo cp -f raspi.list ${mountpoint}/etc/apt/sources.list.d/
    sudo cp -f cmdline.txt ${mountpoint}/boot/
    sudo cp -f config.txt ${mountpoint}/boot/

    bootpartuuid=$(sudo blkid -s PARTUUID | grep ${loop}p1 | sed -e 's#.*=\"\(.*\)\"#\1#')
    rootpartuuid=$(sudo blkid -s PARTUUID | grep ${loop}p2 | sed -e 's#.*=\"\(.*\)\"#\1#')
    sudo sed -e "s|%BOOTPARTUUID%|${bootpartuuid}|" -i ${mountpoint}/etc/fstab
    sudo sed -e "s|%ROOTPARTUUID%|${rootpartuuid}|" -i ${mountpoint}/etc/fstab
    sudo sed -e "s|%ROOTPARTUUID%|${rootpartuuid}|" -i ${mountpoint}/boot/cmdline.txt

    # sudo tee -a ${mountpoint}/etc/hosts << EOF
    # $(ping -c1 deb.debian.org| head -1 | cut -d '(' -f3 | cut -d ')' -f1)           deb.debian.org
    # $(ping -c1 archive.raspberrypi.org| head -1 | cut -d '(' -f3 | cut -d ')' -f1)  archive.raspberrypi.org
    # $(ping -c1 deb.grml.org| head -1 | cut -d '(' -f3 | cut -d ')' -f1)             deb.grml.org
    # EOF

    sudo cp initialize.sh ${mountpoint}/root

    sudo LC_ALL=C PATH="${chroot_path}" chroot ${mountpoint} /bin/bash -c "/root/initialize.sh"

    sudo rm ${mountpoint}/root/initialize.sh
}

cleanup() {
    echo "cleanup"

    sudo umount -R ${mountpoint} || :
    sudo losetup -D

    if [ -f ${img} ]; then
        cp -f ${img} ${script_dir}
        rm ${img}
    fi
}
trap cleanup EXIT

################################################################################
start_time=$(date +%s)

echo "****************************************************************"
echo "                Create Raspberry Pi image                "
echo "****************************************************************"

create_img
configure_img
cleanup

end_time=$(date +%s)
total_time=$((end_time-start_time))

echo "****************************************************************"
echo "                Execution time Information                "
echo "****************************************************************"
echo "${script_name} : End time - $(date)"
echo "${script_name} : Total time - $(date -d@${total_time} -u +%H:%M:%S)"
