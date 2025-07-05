#!/bin/bash
#
# mkimg
#

set -e
set -u
set -o pipefail
# set -x

umask 0022

SCRIPT_NAME="$(basename "$0")"
SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

################################################################################

unset __DEBUG__
__DEBUG__=1

### general libraries
. "$SCRIPT_DIR"/lib/log.sh
. "$SCRIPT_DIR"/lib/utils.sh
. "$SCRIPT_DIR"/lib/chroot.sh
. "$SCRIPT_DIR"/lib/loop.sh
. "$SCRIPT_DIR"/lib/pacman.sh
. "$SCRIPT_DIR"/lib/deb.sh

### checks
check_root

### constants and variables
declare -r TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

declare -r WORK_DIR="/tmp/mkimg_$TIMESTAMP"
declare -r ROOTFS_DIR="$WORK_DIR/rootfs"
declare -r LOG_DIR="$WORK_DIR/log"

declare -r IMG_FILE="$WORK_DIR/mkimg.img"

loop_device=""

### options and arguments
arg_target=""
arg_suite=""
arg_rootfs_tarball=""

### functions
make_work_dirs() {
    info "Making work directory: $WORK_DIR"
    if [[ -d "$WORK_DIR" ]]; then
        error "Working directory $WORK_DIR already exists" 1
    fi
    mkdir -vp -- "$WORK_DIR"
    mkdir -vp -- "$ROOTFS_DIR"
    mkdir -vp -- "$LOG_DIR"
    info "Done (work directory)"
}

make_img_file_pc() {
    info "Making image for PC..."
    fallocate -l 3GiB "$IMG_FILE"
    parted -s "$IMG_FILE" \
        mktable gpt \
        unit s \
        mkpart BOOT fat32 2048s 1048575s \
        mkpart RECOVERY ext4 1048576s 5242879s \
        print \
        > "$LOG_DIR/${FUNCNAME[0]}.log"
    info "Done ($IMG_FILE: $_size)"
}
make_img_file_rpi() {
    info "Making image for Raspberry Pi..."
    fallocate -l 1536MiB "$IMG_FILE"
    parted -s "$IMG_FILE" \
        mktable msdos \
        unit s \
        mkpart primary fat32 1s 524287s \
        mkpart primary ext4 524288s 100% \
        print \
        > "$LOG_DIR/${FUNCNAME[0]}.log"
    info "Done ($IMG_FILE: $_size)"
}

setup_loopdev() {
    local _img_file="$1"

    info "Setting up loop device for image: $_img_file"
    if [[ ! -f "$_img_file" && ! -b "$_img_file" ]]; then
        error "Image file does not exist: $_img_file" 2
    fi

    loop_device="$(loop_get_device)"
    if [[ -z "$loop_device" ]]; then
        error "No unused loop device found" 2
    fi
    loop_partitioned_setup "$loop_device" "$_img_file"
    info "Done (Setup loop device: $loop_device)"
}

make_filesystem_pc() {
    info "Making filesystems..."
    mkfs.fat -F 32 -n BOOT "${loop_device}p1" >> "$LOG_DIR/${FUNCNAME[0]}.log"
    mkfs.ext4 -L RECOVERY "${loop_device}p2" >> "$LOG_DIR/${FUNCNAME[0]}.log"
    info "Done (Made filesystems)"
}
make_filesystem_rpi() {
    info "Making filesystems..."
    mkfs.fat -F 32 -n BOOT "${loop_device}p1" >> "$LOG_DIR/${FUNCNAME[0]}.log"
    mkfs.ext4 -L ROOT "${loop_device}p2" >> "$LOG_DIR/${FUNCNAME[0]}.log"
    info "Done (Made filesystems)"
}

mount_loopdev_pc() {
    info "Mounting loop device for PC..."
    mount "${loop_device}p2" "$ROOTFS_DIR"
    mkdir -vp -- "$ROOTFS_DIR/boot"
    mount "${loop_device}p1" "$ROOTFS_DIR"/boot
    info "Done (Mounted loop device for PC)"
}
mount_loopdev_rpi() {
    info "Mounting loop device for RPi..."
    mount "${loop_device}p2" "$ROOTFS_DIR"
    mkdir -vp -- "$ROOTFS_DIR/boot/firmware"
    mount "${loop_device}p1" "$ROOTFS_DIR"/boot/firmware
    info "Done (Mounted loop device for RPi)"
}

bootstrap_rootfs() {
    info "Extracting root filesystem..."
    tar -v \
        --zstd \
        --xattrs --acls \
        --numeric-owner \
        -xpf "$arg_rootfs_tarball" \
        -C "$ROOTFS_DIR" \
        > "$LOG_DIR/tar.log"
    info "Done (Extracted root filesystem)"
}

usage() {
    cat << EOF

Usage: $SCRIPT_NAME -h|--help
Usage: $SCRIPT_NAME -t|--target <target>

    -h, --help                      print this help message and exit
    -t, --target <target>           specify target system (pc,rpi)

EOF
}

################################################################################

while (( $# > 0 )); do
    case "$1" in
    -h | --help)
        usage
        exit
        ;;
    -t | --target)
        shift
        arg_target="$1"
        ;;
    *)
        usage
        error "Unknown option: $1" 128
        ;;
    esac
    shift
done

make_img_file=""
make_filesystem=""
mount_loopdev=""
case "$arg_target" in
pc)
    make_img_file="make_img_file_pc"
    make_filesystem="make_filesystem_pc"
    mount_loopdev="mount_loopdev_pc"
    ;;
rpi)
    make_img_file="make_img_file_rpi"
    make_filesystem="make_filesystem_rpi"
    mount_loopdev="mount_loopdev_rpi"
    ;;
*)
    error "Unknown target: $arg_target" 1
    ;;
esac


################################################################################

prologue

make_work_dirs
"$make_img_file"
setup_loopdev "$IMG_FILE"
"$make_filesystem"
"$mount_loopdev"
bootstrap_rootfs
configure_rootfs

cleanup

epilogue

### error code
# 1: general error
# 128: Unknown option
