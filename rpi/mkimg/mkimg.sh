#!/bin/bash
#
# mkimg.sh
#

script_name="$(basename "$0")"
script_path="$(readlink -f "$0")"
script_dir="$(dirname "$script_path")"
img="/tmp/raspi.img"
mountpoint="/tmp/raspi"
loop=""
chroot_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
target=""
fs="f2fs"
base_only=0
base_img=""

# Show an INFO message
# $1: message string
info() {
    local _msg="$1"
    printf '\033[0;32m[%s] INFO: %s\033[0m\n' "$script_name" "$_msg"
}

# Show a WARNING message
# $1: message string
warning() {
    local _msg="$1"
    printf '\033[0;33m[%s] WARNING: %s\033[0m\n' "$script_name" "$_msg" >&2
}

# Show an ERROR message then exit with status
# $1: message string
# $2: exit code number (with 0 does not exit)
error() {
    local _msg="$1"
    local _error="$2"
    printf '\033[0;31m[%s] ERROR: %s\033[0m\n' "$script_name" "$_msg" >&2
    if [ "$_error" -gt 0 ]; then
        exit "$_error"
    fi
}

usage() {
    local _usage="
    Usage: $script_name [ -h | --help ] -t|--target <target> [ -b|--base-onle | -u|--use-base <basee_image> ]

    -h, --help                      display this help message and exit
    -t, --target                    specify the target image (debian, ubuntu)
    -b, --base-onle                 only create base image
    -u, --use-base <base_image>     use existing base image
"
    echo "$_usage"
}

create_img() {
    info "Creating image..."

    if [ -f "$img" ]; then
        rm -f "$img"
    fi

    fallocate -l 1280MiB "$img"

    parted -s "$img" \
        mktable msdos \
        unit s \
        mkpart primary fat32 1s 524287s \
        mkpart primary "$fs" 524288s 100% \
        print
}

setup_loop() {
    info "Setup loop device..."

    loop=$(losetup -f)
    info "Loop device is \"$loop\""

    sudo losetup -P "$loop" "$img"
}

format_img() {
    info "Formating image..."

    sudo mkfs.fat -F32 "${loop}p1"
    sudo mkfs."$fs" "${loop}p2"
}

mount_img() {
    info "Mounting image..."

    mkdir -p "$mountpoint"
    sudo mount "${loop}p2" "$mountpoint"
    sudo mkdir -p "$mountpoint"/boot/firmware
    sudo mount "${loop}p1" "$mountpoint"/boot/firmware
}

bootstrap_img () {
    info "Bootstrap image..."

    # debootstrap
    if [ "$target" == "debian" ]; then
        sudo debootstrap --arch=arm64 --foreign bookworm "$mountpoint" http://deb.debian.org/debian
    elif [ "$target" == "ubuntu" ]; then
        sudo debootstrap --arch=arm64 --foreign jammy "$mountpoint" http://ports.ubuntu.com/ubuntu-ports
    fi

    sudo LC_ALL=C PATH="$chroot_path" chroot "$mountpoint" /debootstrap/debootstrap --second-stage

    sync
}

configure_img() {
    info "Configuring image..."

    # source.list
    sudo cp -f "sources-$target.list" "$mountpoint"/etc/apt/sources.list
    if [ "$target" == "debian" ]; then
        sudo cp -f raspi.list "$mountpoint"/etc/apt/sources.list.d/
        wget -qO - http://archive.raspberrypi.org/debian/raspberrypi.gpg.key | gpg --dearmor | sudo tee "$mountpoint"/etc/apt/trusted.gpg.d/raspberrypi >/dev/null
    fi

    # initialization script
    info "Running initialize.sh..."
    sudo cp "initialize-$target.sh" "$mountpoint"/initialize.sh

    for fs in dev sys proc run; do
        sudo mount --rbind /"$fs" "$mountpoint/$fs"
        sudo mount --make-rslave "$mountpoint/$fs"
    done

    sudo LC_ALL=C PATH="$chroot_path" chroot "$mountpoint" /bin/bash -c "/initialize.sh"

    sudo rm "$mountpoint"/initialize.sh

    for fs in dev sys proc run; do
        sudo umount -R "$mountpoint"/$fs
    done

    info "Clean mountpoint..."
    sudo rm -rf "$mountpoint"/var/lib/apt/lists/*
    sudo rm -rf "$mountpoint"/dev/*
    sudo rm -rf "$mountpoint"/var/log/*
    sudo rm -rf "$mountpoint"/var/cache/apt/archives/*.deb
    sudo rm -rf "$mountpoint"/var/tmp/*
    sudo rm -rf "$mountpoint"/tmp/*

    sudo cp -f "config.txt" "$mountpoint"/boot/firmware/config.txt
    sudo cp -f "cmdline-$target.txt" "$mountpoint"/boot/firmware/cmdline.txt
    sudo cp -f fstab "$mountpoint"/etc/fstab

    # PARTUUID
    bootpartuuid=$(sudo blkid -s PARTUUID | grep ${loop}p1 | sed -e 's#.*=\"\(.*\)\"#\1#')
    test -z "$bootpartuuid" && error "cannot find boot partuuid!" 1
    info "BOOT PARTUUID: $bootpartuuid"
    rootpartuuid=$(sudo blkid -s PARTUUID | grep ${loop}p2 | sed -e 's#.*=\"\(.*\)\"#\1#')
    test -z "$rootpartuuid" && error "cannot find root partuuid!" 1
    info "ROOT PARTUUID: $rootpartuuid"
    sudo sed -i "s|%BOOTPARTUUID%|$bootpartuuid|" "$mountpoint"/etc/fstab
    sudo sed -i "s|%ROOTPARTUUID%|$rootpartuuid|" "$mountpoint"/etc/fstab
    sudo sed -i "s|%ROOTPARTUUID%|$rootpartuuid|" $mountpoint/boot/firmware/cmdline.txt

    # RPi firmware
    if [ "$target" == "ubuntu" ]; then
        sudo cp -dr "$script_dir"/firmware/boot/* "$mountpoint"/boot/firmware/
        sudo cp -dr "$script_dir"/firmware/modules "$mountpoint"/usr/lib/
        sudo cp -dr "$script_dir"/firmware/opt/vc "$mountpoint"/opt/
    fi

    sync
}

cleanup() {
    info "Cleaning..."
    set +e

    if [ -n "$mountpoint" ]; then
        for attempt in $(seq 10); do
            for fs in dev/pts dev sys proc run; do
                mount | grep -q "$mountpoint/$fs" && sudo umount -R "$mountpoint/$fs" 2> /dev/null
            done
            mount | grep -q "$mountpoint" && sudo umount -R "$mountpoint" 2> /dev/null
            if [ $? -ne 0 ]; then
                break
            fi
            sleep 1
        done
    fi

    if [ -n "$loop" ]; then
        sudo losetup -d "$loop"
    fi
    if [ -d "$mountpoint" ]; then
        rmdir "$mountpoint"
    fi
}
trap cleanup EXIT

################################################################################

set -e -u
# set -x

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
    -f|--filesystem)
        shift
        fs="$1"
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

if [ "$fs" != "f2fs" ] && [ "$fs" != "ext4" ]; then
    usage
    error "Unsupported filesystem type \"$fs\"." 2
fi

if [ -d "$mountpoint" ]; then
    error "$mountpoint exists, please remove before restart!" 3
fi

start_time=$(date +%s)

echo    "****************************************************************"
echo    "               Create Raspberry Pi image                "
echo    "****************************************************************"

# does not use a base image
if [ ! -f "$base_img" ]; then
    create_img
    setup_loop
    format_img
    mount_img
    bootstrap_img
    info "Copy base image..."
    cp "$img" "$script_dir/raspi_${target}_${fs}_base_$(date +%Y%m%d%H%M%S).img"
    if [ "$base_only" -eq 0 ]; then
        configure_img
        info "Copy full image..."
        cp "$img" "$script_dir/raspi_${target}_${fs}_$(date +%Y%m%d%H%M%S).img"
    fi
# use a base image
elif [ "$base_only" -eq 0 ]; then
    cp "$base_img" "$img"
    setup_loop
    mount_img
    configure_img
    info "Copy full image..."
    cp "$img" "$script_dir/raspi_${target}_${fs}_$(date +%Y%m%d%H%M%S).img"
else
    info "Nothing to do."
fi

end_time=$(date +%s)
total_time=$((end_time-start_time))

echo -e "\e[1;30m"
echo -e "****************************************************************"
echo -e "                Execution time Information                "
echo -e "****************************************************************"
echo -e "[$script_name]: End time - $(date)"
echo -e "[$script_name]: Total time - $(date -d@$total_time -u +%H:%M:%S)"
echo -e "\e[0m"
