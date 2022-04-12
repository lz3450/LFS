#!/bin/bash
#
# mkimg.sh
#

set -e
# set -x

script_name="$(basename "${0}")"
script_path="$(readlink -f "${0}")"
script_dir="$(dirname "${script_path}")"
img="/dev/shm/raspi.img"
mountpoint="/dev/shm/raspi"
chroot_path="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"

# Show an INFO message
# $1: message string
info() {
    local _msg="${1}"
    printf '[%s] INFO: %s\n' "${script_name}" "${_msg}"
}

# Show a WARNING message
# $1: message string
warning() {
    local _msg="${1}"
    printf '[%s] WARNING: %s\n' "${script_name}" "${_msg}" >&2
}

# Show an ERROR message then exit with status
# $1: message string
# $2: exit code number (with 0 does not exit)
error() {
    local _msg="${1}"
    local _error=${2}
    printf '[%s] ERROR: %s\n' "${script_name}" "${_msg}" >&2
    if (( _error > 0 )); then
        exit "${_error}"
    fi
}

create_img() {
    info "Creating image..."
    fallocate -l 1536M ${img}

    parted -s ${img} \
        mktable msdos \
        unit s \
        mkpart primary fat32 1s 262143s \
        mkpart primary ext4 262144s 100% \
        set 2 lba off \
        print

    loop=$(losetup -f)
    info "Loop device is \"$loop\""

    losetup -P ${loop} ${img}

    mkfs.fat -F32 ${loop}p1
    mkfs.ext4 ${loop}p2

    mkdir -p "${mountpoint}"
    mount ${loop}p2 "${mountpoint}"
    mkdir -p "${mountpoint}"/boot
    mount ${loop}p1 "${mountpoint}"/boot
}

configure_img() {
    info "Configuring image..."
    # debootstrap
    debootstrap --arch=arm64 --foreign testing "${mountpoint}" http://ftp.debian.org/debian
    # debootstrap --arch=arm64 --foreign stable "${mountpoint}" http://ftp.debian.org/debian
    # cp /usr/bin/qemu-aarch64-static "${mountpoint}"/usr/bin
    LC_ALL=C PATH="${chroot_path}" chroot "${mountpoint}" /debootstrap/debootstrap --second-stage

    echo "RPi" > "${mountpoint}"/etc/hostname
    cp -f fstab "${mountpoint}"/etc/
    cp -f sources.list "${mountpoint}"/etc/apt/
    cp -f raspi.list "${mountpoint}"/etc/apt/sources.list.d/
    cp -f cmdline.txt "${mountpoint}"/boot/
    cp -f config.txt "${mountpoint}"/boot/

    wget -qO "${mountpoint}"/etc/apt/trusted.gpg.d/raspberrypi http://archive.raspberrypi.org/debian/raspberrypi.gpg.key
    gpg --dearmor "${mountpoint}"/etc/apt/trusted.gpg.d/raspberrypi
    rm -f "${mountpoint}"/etc/apt/trusted.gpg.d/raspberrypi

    bootpartuuid=$(blkid -s PARTUUID | grep ${loop}p1 | sed -e 's#.*=\"\(.*\)\"#\1#')
    rootpartuuid=$(blkid -s PARTUUID | grep ${loop}p2 | sed -e 's#.*=\"\(.*\)\"#\1#')
    sed -e "s|%BOOTPARTUUID%|${bootpartuuid}|" -i ${mountpoint}/etc/fstab
    sed -e "s|%ROOTPARTUUID%|${rootpartuuid}|" -i ${mountpoint}/etc/fstab
    sed -e "s|%ROOTPARTUUID%|${rootpartuuid}|" -i ${mountpoint}/boot/cmdline.txt

    # tee -a "${mountpoint}"/etc/hosts << EOF
    # $(ping -c1 deb.debian.org| head -1 | cut -d '(' -f3 | cut -d ')' -f1)           deb.debian.org
    # $(ping -c1 archive.raspberrypi.org| head -1 | cut -d '(' -f3 | cut -d ')' -f1)  archive.raspberrypi.org
    # $(ping -c1 deb.grml.org| head -1 | cut -d '(' -f3 | cut -d ')' -f1)             deb.grml.org
    # EOF

    cp initialize.sh "${mountpoint}"/root

    for fs in dev sys proc run; do
        mount --rbind /$fs "${mountpoint}"/$fs
        mount --make-rslave "${mountpoint}"/$fs
    done

    LC_ALL=C PATH="${chroot_path}" chroot "${mountpoint}" /bin/bash -c "/root/initialize.sh"

    for fs in dev sys proc run; do
        umount -R "${mountpoint}"/$fs
    done

    rm "${mountpoint}"/root/initialize.sh

    sudo rm -rf var/lib/apt/lists/*
    sudo rm -rf dev/*
    sudo rm -rf var/log/*
    sudo rm -rf var/cache/apt/archives/*.deb
    sudo rm -rf var/tmp/*
    sudo rm -rf tmp/*
}

cleanup() {
    info "Cleaning..."
    set +e

    if [ -n "${mountpoint}" ]; then
        for attempt in $(seq 10); do
            for fs in dev/pts dev sys proc run; do
                mount | grep -q "${tmpdir}/$fs" && umount -R "${mountpoint}"/$fs 2> /dev/null
            done
            mount | grep -q "${mountpoint}" && umount -R "${mountpoint}" 2> /dev/null
            if [ $? -ne 0 ]; then
                break
            fi
            sleep 1
        done
    fi

    losetup -D
    rmdir "${mountpoint}"

    if [ -f ${img} ]; then
        rm -f ${img}
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
cp -f ${img} "${script_dir}/raspi_$(date +%Y%m%d%H%M%S).img"

end_time=$(date +%s)
total_time=$((end_time-start_time))

echo "****************************************************************"
echo "                Execution time Information                "
echo "****************************************************************"
echo "${script_name} : End time - $(date)"
echo "${script_name} : Total time - $(date -d@${total_time} -u +%H:%M:%S)"
