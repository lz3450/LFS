#!/bin/bash
#
# mkimg.sh
#

set -e -u
# set -x

script_name="$(basename "$0")"
script_path="$(readlink -f "$0")"
script_dir="$(dirname "${script_path}")"
img="/tmp/raspi.img"
mountpoint="/tmp/raspi"
loop=""
chroot_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
target=""
base_only=0
base_img=""

# Show an INFO message
# $1: message string
info() {
    local _msg="$1"
    printf '[%s] INFO: %s\n' "${script_name}" "${_msg}"
}

# Show a WARNING message
# $1: message string
warning() {
    local _msg="$1"
    printf '[%s] WARNING: %s\n' "${script_name}" "${_msg}" >&2
}

# Show an ERROR message then exit with status
# $1: message string
# $2: exit code number (with 0 does not exit)
error() {
    local _msg="$1"
    local _error="$2"
    printf '[%s] ERROR: %s\n' "${script_name}" "${_msg}" >&2
    if [ "${_error}" -gt 0 ]; then
        exit "${_error}"
    fi
}

usage() {
    local _usage="
    Usage: ${script_name} [ -h | --help ] -t|--target <target> [ -b|--base-onle | -u|--use-base <basee_image> ]

    -h, --help                      display this help message and exit
    -t, --target                    specify the target image (debian, ubuntu)
    -b, --base-onle                 only create base image
    -u, --use-base <base_image>     use existing base image
"
    echo "${_usage}"
}

create_img() {
    info "Creating image..."

    fallocate -l 3G "$img"

    parted -s "$img" \
        mktable msdos \
        unit s \
        mkpart primary fat32 1s 524287s \
        mkpart primary f2fs 524288s 100% \
        print
}

setup_loop() {
    info "Setup loop device..."

    loop=$(losetup -f)
    info "Loop device is \"${loop}\""

    losetup -P "${loop}" "$img"
}

format_img() {
    info "Formating image..."

    mkfs.fat -F32 "${loop}p1"
    mkfs.f2fs "${loop}p2"
}

mount_img() {
    info "Mounting image..."

    mkdir -p "$mountpoint"
    mount "${loop}p2" "$mountpoint"
    if [ "$target" == "debian" ]; then
        mkdir -p "$mountpoint"/boot
        mount "${loop}p1" "$mountpoint"/boot
    elif [ "$target" == "ubuntu" ]; then
        mkdir -p "$mountpoint"/boot/firmware
        mount "${loop}p1" "$mountpoint"/boot/firmware
    fi
}

bootstrap_img () {
    info "Bootstrap image..."

    # debootstrap
    if [ "$target" == "debian" ]; then
        debootstrap --arch=arm64 --foreign testing "$mountpoint" http://ftp.debian.org/debian
        # debootstrap --arch=arm64 --foreign stable "$mountpoint" http://ftp.debian.org/debian
    elif [ "$target" == "ubuntu" ]; then
        debootstrap --arch=arm64 --foreign jammy "$mountpoint" http://ports.ubuntu.com/ubuntu-ports
    fi

    LC_ALL=C PATH="$chroot_path" chroot "$mountpoint" /debootstrap/debootstrap --second-stage

    echo "RPi" > "$mountpoint"/etc/hostname

    cp -f "cmdline-$target.txt" "$mountpoint"/boot/firmware/cmdline.txt
    cp -f "config-$target.txt" "$mountpoint"/boot/firmware/config.txt

    cp -f fstab "$mountpoint"/etc/fstab
    cp -f "sources-$target.list" "$mountpoint"/etc/apt/sources.list

    if [ "$target" == "debian" ]; then
        cp -f raspi.list "$mountpoint"/etc/apt/sources.list.d/
        wget -qO "$mountpoint"/etc/apt/trusted.gpg.d/raspberrypi http://archive.raspberrypi.org/debian/raspberrypi.gpg.key
        gpg --dearmor "$mountpoint"/etc/apt/trusted.gpg.d/raspberrypi
        rm -f "$mountpoint"/etc/apt/trusted.gpg.d/raspberrypi
    fi

    # Partation UUID
    bootpartuuid=$(blkid -s PARTUUID | grep ${loop}p1 | sed -e 's#.*=\"\(.*\)\"#\1#')
    rootpartuuid=$(blkid -s PARTUUID | grep ${loop}p2 | sed -e 's#.*=\"\(.*\)\"#\1#')
    sed -e "s|%BOOTPARTUUID%|${bootpartuuid}|" -i $mountpoint/etc/fstab
    sed -e "s|%ROOTPARTUUID%|${rootpartuuid}|" -i $mountpoint/etc/fstab
    if [ "$target" == "debian" ]; then
        sed -e "s|%ROOTPARTUUID%|${rootpartuuid}|" -i $mountpoint/boot/cmdline.txt
    elif [ "$target" == "ubuntu" ]; then
        sed -e "s|%ROOTPARTUUID%|${rootpartuuid}|" -i $mountpoint/boot/firmware/cmdline.txt
    fi

    sync
}

configure_img() {
    info "Configuring image..."

    cp "initialize-$target.sh" "$mountpoint"/root/initialize.sh

    for fs in dev sys proc run; do
        mount --rbind /"$fs" "$mountpoint/$fs"
        mount --make-rslave "$mountpoint/$fs"
    done

    info "Running initialize.sh..."
    LC_ALL=C PATH="$chroot_path" chroot "$mountpoint" /bin/bash -c "/root/initialize.sh"
    LC_ALL=C PATH="$chroot_path" chroot "$mountpoint" sync

    rm "$mountpoint"/root/initialize.sh

    for fs in dev sys proc run; do
        umount -R "$mountpoint"/$fs
    done

    rm -rf var/lib/apt/lists/*
    rm -rf dev/*
    rm -rf var/log/*
    rm -rf var/cache/apt/archives/*.deb
    rm -rf var/tmp/*
    rm -rf tmp/*

    sync
}

cleanup() {
    info "Cleaning..."
    set +e

    if [ -n "$mountpoint" ]; then
        for attempt in $(seq 10); do
            for fs in dev/pts dev sys proc run; do
                mount | grep -q "$mountpoint/${fs}" && umount -R "$mountpoint/${fs}" 2> /dev/null
            done
            mount | grep -q "$mountpoint" && umount -R "$mountpoint" 2> /dev/null
            if [ $? -ne 0 ]; then
                break
            fi
            sleep 1
        done
    fi

    losetup -D
    if [ -d "$mountpoint" ]; then
        rmdir "$mountpoint"
    fi

    if [ -f "$img" ]; then
        rm -f "$img"
    fi
}
trap cleanup EXIT

################################################################################

while [ $# -gt 0 ]; do
    case "$1" in
    -h|--help)
        usage
        exit 0
        ;;
    -t|--target)
        shift
        target="$1"
        ;;
    -b|--base-only)
        base_only=1
        ;;
    -u|--use-base)
        shift
        base_img="$(readlink -f "$1")"
        ;;
    *)
        usage
        error "Unknown option: $1" 1
        ;;
    esac
    shift
done

if [ -z "$target" ] || ([ "$target" != "debian" ] && [ "$target" != "ubuntu" ]); then
    usage
    error "Incurrect or no <target> provided." 1
fi

if [ -d "$mountpoint" ]; then
    error "$mountpoint exists, please remove before restart!" 3
fi

start_time=$(date +%s)

echo    "****************************************************************"
echo    "               Create Raspberry Pi image                "
echo    "****************************************************************"

# base image not exists
if [ ! -f "$base_img" ]; then
    create_img
    setup_loop
    format_img
    mount_img
    bootstrap_img
    info "Copy base image..."
    cp -f "$img" "$script_dir/raspi_${target}_base_$(date +%Y%m%d%H%M%S).img"
    if [ "$base_only" -eq 0 ]; then
        configure_img
        info "Copy full image..."
        cp -f "$img" "$script_dir/raspi_${target}_$(date +%Y%m%d%H%M%S).img"
    fi
# base image exists
elif [ "$base_only" -eq 0 ]; then
    cp "$base_img" "$img"
    setup_loop
    mount_img
    configure_img
    info "Copy full image..."
    cp -f "$img" "$script_dir/raspi_${target}_$(date +%Y%m%d%H%M%S).img"
else
    error "Nothing to do." 0
fi

end_time=$(date +%s)
total_time=$((end_time-start_time))

echo    "****************************************************************"
echo    "               Execution time Information                "
echo    "****************************************************************"
echo "$script_name : End time - $(date)"
echo "$script_name : Total time - $(date -d@$total_time -u +%H:%M:%S)"
