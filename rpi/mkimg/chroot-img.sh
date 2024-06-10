#!/bin/bash
#
# chroot-img.sh
#

script_name="$(basename "$0")"
script_path="$(readlink -f "$0")"
script_dir="$(dirname "$script_path")"
mountpoint="$(mktemp -d)"
file_name=""
is_device=0
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
    if [[ "$_error" -gt 0 ]]; then
        exit "$_error"
    fi
}

# usage() {
#     local _usage="
#     Usage: $script_name [ -h | --help ] -t|--target <target> [ -b|--base-onle | -u|--use-base <basee_image> ]

#     -h, --help                      display this help message and exit
#     -t, --target                    specify the target image (debian, ubuntu)
# "
#     echo "$_usage"
# }

# find_image_file() {
#     if [ $base -eq 0 ]; then
#         img=`find . -name "*.img" | grep -Po "raspi_${target}_\d+\.img" | sort | tail -n1`
#     else
#         img=`find . -name "*.img" | grep -Po "raspi_${target}_base_\d+\.img" | sort | tail -n1`
#     fi
#     info "Image file is \"$file_name\""
# }

find_image_file() {
    if [[ -f "$file_name" ]]; then
        is_device=0
        info "Image file is \"$file_name\""
    elif [[ -b "$file_name" ]]; then
        is_device=1
        info "Device is \"$file_name\""
    else
        error "Cannot find image file or device \"$file_name\"." 1
    fi
}

setup_loop() {
    info "Setup loop device..."

    loop=$(losetup -f)
    info "Loop device is \"$loop\""

    sudo losetup -P "$loop" "$file_name"
}

mount_device() {
    if [[ $is_device -eq 0 ]]; then
        setup_loop
        device_name="${loop}p"
    else
        device_name="$file_name"
        mount | grep -q "${device_name}1" && sudo umount "${device_name}1"
        mount | grep -q "${device_name}2" && sudo umount "${device_name}2"
    fi

    info "Mointing the image..."
    mkdir -p "$mountpoint"
    sudo mount "${device_name}2" "$mountpoint"
    info "Mountpoint is \"$mountpoint\""

    # Check if the mount was successful
    if mountpoint -q "$mountpoint"; then
        info "Successfully mounted ${device_name}2 to $mountpoint"
    else
        error "Failed to mount ${device_name}2 to \"$mountpoint\"" 1
    fi

    sudo mkdir -p "$mountpoint"/boot/firmware
    sudo mount "${device_name}1" "$mountpoint"/boot/firmware

    for fs in dev sys proc run; do
        sudo mount --rbind /"$fs" "$mountpoint/$fs"
        sudo mount --make-rslave "$mountpoint/$fs"
    done
}

cleanup() {
    info "Cleaning..."
    set +e

    if [[ -n "$mountpoint" ]]; then
        for attempt in {1..10}; do
            for fs in dev/pts dev sys proc run; do
                mountpoint -q "$mountpoint/$fs" && sudo umount -R "$mountpoint/$fs" 2> /dev/null
            done
            mountpoint -q "$mountpoint" && sudo umount -R "$mountpoint" 2> /dev/null
            if [[ $? -ne 0 ]]; then
                break
            fi
            sleep 1
        done
    fi

    if [[ -n "$loop" ]]; then
        sudo losetup -d "$loop"
    fi
    if [[ -d "$mountpoint" ]]; then
        rmdir "$mountpoint"
    fi
}
trap cleanup EXIT SIGINT SIGTERM SIGKILL

################################################################################

set -e
# set -x

if (($# > 1)); then
    error "Too many arguments" 1
fi
file_name="$1"

echo -e "\e[1;30m"
echo -e "****************************************************************"
echo -e "               Create Raspberry Pi image                "
echo -e "****************************************************************"
echo -e "[$script_name]: Start time - $(date)"
echo -e "\e[0m"

start_time=$(date +%s)

find_image_file
mount_device
sudo PATH="$chroot_path" chroot "$mountpoint"

end_time=$(date +%s)
total_time=$((end_time - start_time))

echo -e "\e[1;30m"
echo -e "****************************************************************"
echo -e "                Execution time Information                "
echo -e "****************************************************************"
echo -e "[$script_name]: End time - $(date)"
echo -e "[$script_name]: Total time - $(date -d@$total_time -u +%H:%M:%S)"
echo -e "\e[0m"
