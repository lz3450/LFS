#!/bin/bash
#
# mkimg.sh
#

set -e -u
# set -x

script_name="$(basename "${0}")"
script_path="$(readlink -f "${0}")"
script_dir="$(dirname "${script_path}")"
img="/tmp/raspi.img"
mountpoint="/tmp/raspi"
chroot_path="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"
target=""

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
    local _error="${2}"
    printf '[%s] ERROR: %s\n' "${script_name}" "${_msg}" >&2
    if [ "${_error}" -gt 0 ]; then
        exit "${_error}"
    fi
}

usage() {
    echo "Usage: ${script_name} [ -h | --help ] -b|--bsp <bsp_name> [ -c | --clean ] [ -V | --verbose ]"
    echo
    echo "    -h, --help        display this help message and exit"
    echo "    -t, --target      specify the target image (debian, ubuntu)"
    echo
}

create_img() {
    info "Creating image..."
    fallocate -l 4G ${img}

    parted -s ${img} \
        mktable msdos \
        unit s \
        mkpart primary fat32 1s 524287s \
        mkpart primary f2fs 524288s 100% \
        set 2 lba off \
        print

    loop=$(losetup -f)
    info "Loop device is \"$loop\""

    losetup -P ${loop} ${img}

    mkfs.fat -F32 ${loop}p1
    mkfs.f2fs -f ${loop}p2

    mkdir -p "${mountpoint}"
    mount ${loop}p2 "${mountpoint}"
    if [ "${target}" == "debian" ]; then
        mkdir -p "${mountpoint}"/boot
        mount ${loop}p1 "${mountpoint}"/boot
    elif [ "${target}" == "ubuntu" ]; then
        mkdir -p "${mountpoint}"/boot/firmware
        mount ${loop}p1 "${mountpoint}"/boot/firmware
    fi
}

configure_img() {
    info "Configuring image..."

    # debootstrap
    if [ "${target}" == "debian" ]; then
        debootstrap --arch=arm64 --foreign testing "${mountpoint}" http://ftp.debian.org/debian
        # debootstrap --arch=arm64 --foreign stable "${mountpoint}" http://ftp.debian.org/debian
    elif [ "${target}" == "ubuntu" ]; then
        debootstrap --arch=arm64 --foreign jammy "${mountpoint}" http://ports.ubuntu.com/ubuntu-ports
    fi

    # cp /usr/bin/qemu-aarch64-static "${mountpoint}"/usr/bin
    LC_ALL=C PATH="${chroot_path}" chroot "${mountpoint}" /debootstrap/debootstrap --second-stage

    echo "RPi" > "${mountpoint}"/etc/hostname
    cp -f fstab "${mountpoint}"/etc/
    if [ "${target}" == "debian" ]; then
        cp -f sources-debian.list "${mountpoint}"/etc/apt/sources.list
        cp -f raspi.list "${mountpoint}"/etc/apt/sources.list.d/
        cp -f cmdline-debian.txt "${mountpoint}"/boot/cmdline.txt
        cp -f config.txt "${mountpoint}"/boot/

        wget -qO "${mountpoint}"/etc/apt/trusted.gpg.d/raspberrypi http://archive.raspberrypi.org/debian/raspberrypi.gpg.key
        gpg --dearmor "${mountpoint}"/etc/apt/trusted.gpg.d/raspberrypi
        rm -f "${mountpoint}"/etc/apt/trusted.gpg.d/raspberrypi
    elif [ "${target}" == "ubuntu" ]; then
        cp -f sources-ubuntu.list "${mountpoint}"/etc/apt/sources.list
        cp -f cmdline-ubuntu.txt "${mountpoint}"/boot/firmware/cmdline.txt
        cp -f config.txt "${mountpoint}"/boot/firmware/
    fi

    # Partation UUID
    bootpartuuid=$(blkid -s PARTUUID | grep ${loop}p1 | sed -e 's#.*=\"\(.*\)\"#\1#')
    rootpartuuid=$(blkid -s PARTUUID | grep ${loop}p2 | sed -e 's#.*=\"\(.*\)\"#\1#')
    sed -e "s|%BOOTPARTUUID%|${bootpartuuid}|" -i ${mountpoint}/etc/fstab
    sed -e "s|%ROOTPARTUUID%|${rootpartuuid}|" -i ${mountpoint}/etc/fstab
    if [ "${target}" == "debian" ]; then
        sed -e "s|%ROOTPARTUUID%|${rootpartuuid}|" -i ${mountpoint}/boot/cmdline.txt
    elif [ "${target}" == "ubuntu" ]; then
        sed -e "s|%ROOTPARTUUID%|${rootpartuuid}|" -i ${mountpoint}/boot/firmware/cmdline.txt
    fi

    # tee -a "${mountpoint}"/etc/hosts << EOF
    # $(ping -c1 deb.debian.org| head -1 | cut -d '(' -f3 | cut -d ')' -f1)           deb.debian.org
    # $(ping -c1 archive.raspberrypi.org| head -1 | cut -d '(' -f3 | cut -d ')' -f1)  archive.raspberrypi.org
    # $(ping -c1 deb.grml.org| head -1 | cut -d '(' -f3 | cut -d ')' -f1)             deb.grml.org
    # EOF

    if [ "${target}" == "debian" ]; then
        cp initialize-debian.sh "${mountpoint}"/root/initialize.sh
    elif [ "${target}" == "ubuntu" ]; then
        cp initialize-ubuntu.sh "${mountpoint}"/root/initialize.sh
    fi

    for fs in dev sys proc run; do
        mount --rbind /$fs "${mountpoint}"/$fs
        mount --make-rslave "${mountpoint}"/$fs
    done

    info "Running initialize.sh..."
    LC_ALL=C PATH="${chroot_path}" chroot "${mountpoint}" /bin/bash -c "/root/initialize.sh"
    LC_ALL=C PATH="${chroot_path}" chroot "${mountpoint}" sync

    rm "${mountpoint}"/root/initialize.sh

    for fs in dev sys proc run; do
        umount -R "${mountpoint}"/$fs
    done

    rm -rf var/lib/apt/lists/*
    rm -rf dev/*
    rm -rf var/log/*
    rm -rf var/cache/apt/archives/*.deb
    rm -rf var/tmp/*
    rm -rf tmp/*
}

cleanup() {
    info "Cleaning..."
    set +e

    if [ -n "${mountpoint}" ]; then
        for attempt in $(seq 10); do
            for fs in dev/pts dev sys proc run; do
                mount | grep -q "${mountpoint}/$fs" && umount -R "${mountpoint}"/$fs 2> /dev/null
            done
            mount | grep -q "${mountpoint}" && umount -R "${mountpoint}" 2> /dev/null
            if [ $? -ne 0 ]; then
                break
            fi
            sleep 1
        done
    fi

    losetup -D
    if [ -d "${mountpoint}" ]; then
        rmdir "${mountpoint}"
    fi

    if [ -f ${img} ]; then
        rm -f ${img}
    fi
}
trap cleanup EXIT

################################################################################

while [ $# -gt 0 ]; do
    case "${1}" in
    -h|--help)
        usage
        exit 0
        ;;
    -t|--target)
        shift
        target="${1}"
        ;;
    *)
        usage
        error "Unknown option: ${1}" 1
        ;;
    esac
    shift
done

if [ -z "${target}" ] || ([ ${target} != "debian" ] && [ ${target} != "ubuntu" ]); then
    usage
    error "Incurrect or no <target> provided." 1
fi

start_time=$(date +%s)

echo "****************************************************************"
echo "                Create Raspberry Pi image                "
echo "****************************************************************"

create_img
configure_img
cp -f ${img} "${script_dir}/raspi_${target}_$(date +%Y%m%d%H%M%S).img"

end_time=$(date +%s)
total_time=$((end_time-start_time))

echo "****************************************************************"
echo "                Execution time Information                "
echo "****************************************************************"
echo "${script_name} : End time - $(date)"
echo "${script_name} : Total time - $(date -d@${total_time} -u +%H:%M:%S)"
