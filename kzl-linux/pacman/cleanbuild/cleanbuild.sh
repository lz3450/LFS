#!/usr/bin/bash
#
# cleanbuild.sh
#

set -e
set -u
set -o pipefail
# set -x

SCRIPT_NAME="$(basename "$0")"
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
BASH_LIB_DIR=${BASH_LIB_DIR:-"/home/kzl/LFS/bash/lib"}

################################################################################

### libraries
source "$BASH_LIB_DIR/log.sh"

### checks
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root" 1
fi

### constants & variables
VERSION="1.0"

WORK_DIR="/tmp/cleanbuild"
ROOTFS_DIR="$WORK_DIR/rootfs"
USERSPEC="kzl:kzl"
PACMAN_REPO_DIR="home/.repository"
LFS_DIR="home/kzl/LFS"
MAKEPKG_DIR="home/kzl/makepkg"

rootfs_tarball="kzllinux_rootfs.tar.gz"
active_mounts=()
rootfs_pkg_list=(
    base
)

### functions
add_mount() {
    mount "$@"
    active_mounts=(${@: -1} "${active_mounts[@]}")
}

umount_all() {
    for mount_point in "${active_mounts[@]}"; do
        umount -v "$mount_point"
        if mountpoint -q "$mount_point"; then
            error "Failed to unmount $mount_point" 2
        fi
    done
}

setup_rootfs() {
    info "Setting up chroot environment..."

    if [[ -f "$WORK_DIR/setup_rootfs" ]]; then
        info "Chroot environment already set up"
        add_mount -v --bind "$ROOTFS_DIR" "$ROOTFS_DIR"
        return
    fi

    if [[ -d "$ROOTFS_DIR" ]]; then
        error "Rootfs directory already exists: $ROOTFS_DIR" 3
    fi

    mkdir -p -- "$ROOTFS_DIR"
    tar -C "$ROOTFS_DIR" -xpf "$rootfs_tarball"
    add_mount -v --bind "$ROOTFS_DIR" "$ROOTFS_DIR"

    chroot "$ROOTFS_DIR" useradd -m -G adm,wheel -U -s /bin/zsh kzl
    echo kzl:3450 | chroot "$ROOTFS_DIR" chpasswd

    mkdir -p -- "$ROOTFS_DIR/$PACMAN_REPO_DIR"

    touch "$WORK_DIR/${FUNCNAME[0]}"
}

mount_lfs() {
    info "Mounting LFS..."

    for dir in "$LFS_DIR" "$MAKEPKG_DIR"; do
        mkdir -p -- "$ROOTFS_DIR/$dir"
        add_mount -v --bind /"$dir" "$ROOTFS_DIR/$dir"
    done

    touch "$WORK_DIR/${FUNCNAME[0]}"
}

build_debug() {
    arch-chroot "$ROOTFS_DIR" /bin/zsh
}

usage() {
    cat <<EOF
Usage: $script_name -V | --version
Usage: $script_name -h | --help

-V, --version                   print the script version number and exit
-h, --help                      print this help message and exit

EOF
}

clean() {
    info "Cleaning..."

    umount_all

    trap - EXIT SIGINT SIGTERM SIGKILL
}
trap clean EXIT SIGINT SIGTERM SIGKILL

################################################################################

while (( $# > 0 )); do
    case "$1" in
    -c | --clean)
        clean
        rm -rf -- "$WORK_DIR"
        exit
        ;;
    -V | --version)
        echo "$version"
        exit
        ;;
    -h | --help)
        usage
        ;;
    *)
        usage
        error "Unknown option: $1"
        ;;
    esac
    shift
done

################################################################################

prologue


setup_rootfs
mount_lfs
build_debug
clean

epilogue

### error codes
# 1: must be run as root
# 2: failed to unmount
# 3: working directory already exists
