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
WORK_DIR="/tmp/cleanbuild"
ROOTFS_DIR="$WORK_DIR/rootfs"

user_home="/home/kzl"

active_mounts=()

rootfs_tarball="kzllinux_rootfs.tar.gz"

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
    done
}

make_rootfs() {
    info "Making rootfs..."

    if [[ -d "$WORK_DIR" ]]; then
        error "Working directory already exists: $WORK_DIR" 1
    fi

    mkdir -p -- "$ROOTFS_DIR"
    tar -C "$ROOTFS_DIR" -xpf "$rootfs_tarball"
    add_mount --bind "$ROOTFS_DIR" "$ROOTFS_DIR"
    touch "$WORK_DIR/${FUNCNAME[0]}"
}

setup_user() {
    info "Setting up chroot environment..."
    arch-chroot "$ROOTFS_DIR" useradd -m -G adm,wheel -U -s /bin/bash kzl
    # arch-chroot "$ROOTFS_DIR" chpasswd <(echo "kzl:kzl")

    touch "$WORK_DIR/${FUNCNAME[0]}"
}

mount_lfs() {
    info "Mounting LFS..."

    mkdir -p -- "$ROOTFS_DIR"/home/.repository
    add_mount -v --bind /home/.repository "$ROOTFS_DIR"/home/.repository

    mkdir -p -- "$ROOTFS_DIR"/home/kzl/LFS
    add_mount -v --bind "$user_home"/LFS "$ROOTFS_DIR"/home/kzl/LFS

    mkdir -p -- "$ROOTFS_DIR"/home/kzl/makepkg
    add_mount -v --bind "$user_home"/makepkg "$ROOTFS_DIR"/home/kzl/makepkg

    touch "$WORK_DIR/${FUNCNAME[0]}"
}

usage() {
    local _usage="
    Usage: $script_name -V | --version
    Usage: $script_name -h | --help

    -V, --version                   print the script version number and exit
    -h, --help                      print this help message and exit
"
    echo "$_usage"
}

clean() {
    info "Cleaning..."

    umount_all

    if [[ ! -f "$WORK_DIR/mount_lfs" ]]; then
        rm -vrf -- "$WORK_DIR"
    fi

    trap - EXIT SIGINT SIGTERM SIGKILL
}
trap clean EXIT SIGINT SIGTERM SIGKILL

################################################################################

while (( $# > 0 )); do
    case "$1" in
    -V | --version )
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

make_rootfs
setup_user
mount_lfs
clean

epilogue
