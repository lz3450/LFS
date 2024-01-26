#!/bin/bash
#
# chroot_img.sh
#

script_name="$(basename "$0")"
script_path="$(readlink -f "$0")"
script_dir="$(dirname "$script_path")"
mountpoint=/tmp/raspi_img
target=""
base=0
img=""
loop=""
chroot_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

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
"
    echo "$_usage"
}

find_image_file() {
    if [ $base -eq 0 ]; then
        img=`find . -name "*.img" | grep -Po "raspi_${target}_\d+\.img" | sort | tail -n1`
    else
        img=`find . -name "*.img" | grep -Po "raspi_${target}_base_\d+\.img" | sort | tail -n1`
    fi
    info "Image file is \"$img\""
}

setup_loop() {
    info "Setup loop device..."

    loop=$(losetup -f)
    info "Loop device is \"$loop\""

    sudo losetup -P "$loop" "$img"
}

mount_img() {
    info "Mointing the image..."

    mkdir -p "$mountpoint"
    sudo mount ${loop}p2 "$mountpoint"

    # Check if the mount was successful
    if mountpoint -q "$mountpoint"; then
        echo "Successfully mounted ${loop}p2 to $mountpoint"
    else
        error "Failed to mount ${loop}p2 to \"$mountpoint\"" 1
    fi

    sudo mkdir -p "$mountpoint"/boot/firmware
    sudo mount "${loop}p1" "$mountpoint"/boot/firmware

    for fs in dev sys proc run; do
        sudo mount --rbind /"$fs" "$mountpoint/$fs"
        sudo mount --make-rslave "$mountpoint/$fs"
    done
}

cleanup() {
    info "Cleaning..."
    set +e

    if [ -n "$mountpoint" ]; then
        for attempt in $(seq 10); do
            for fs in dev/pts dev sys proc run; do
                mountpoint -q "$mountpoint/$fs" && sudo umount -R "$mountpoint/$fs" 2> /dev/null
            done
            mountpoint -q "$mountpoint" && sudo umount -R "$mountpoint" 2> /dev/null
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
trap cleanup EXIT SIGINT

################################################################################

set -e
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
    -b|--base)
        shift
        base=1
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

find_image_file
setup_loop
mount_img
sudo PATH="$chroot_path" chroot "$mountpoint"/
