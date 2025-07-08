#!/bin/bash
#
# install-pc.sh
#

################################################################################

if [[ -v __INSTALL_RPI__ ]]; then
    return
fi

declare -r __INSTALL_RPI__="install-rpi.sh"

################################################################################

### constants and variables
loop_device=""

### libraries
LIBDIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1; pwd -P)"
. "$LIBDIR/chroot.sh"

### functions
prepare_rootfs() {
    info "Preparing root filesystem on $loop_device..."

    # mkpart
    info "Setting up loop device for installation for RPi..."
    fallocate -l 1536MiB "$IMG_FILE"

    parted -s "$target_installation_device" \
        mklabel msdos \
        mkpart primary fat32 1s 524287s \
        mkpart primary ext4 524288s 100% \
        print

    loop_device="$(loop_get_device)"
    readonly loop_device
    loop_partitioned_setup "$loop_device" "$IMG_FILE"

    # mkfs
    mkfs.fat -F 32 -n "BOOT" "${loop_device}p1"
    mkfs.ext4 -L "ROOT" "${loop_device}p2"

    # mount
    mount -o "$MOUNT_OPT" -- "${loop_device}p2" "$ROOTFS_DIR"
    mkdir -vp -- "$ROOTFS_DIR/boot/firmware"
    mount -o "$MOUNT_OPT" -- "${loop_device}p1" "$ROOTFS_DIR/boot/firmware"
}

pre_install_pkgs() {
    :
}

install_pacman_pkgs() {
    :
}


post_install_pkgs() {
    :
}

configure_rootfs_platform_specific() {
    :
}

cleanup_platform_specific() {
    set +e
    chroot_teardown
    loop_teardown "$loop_device"
}

debug "${BASH_SOURCE[0]} sourced"
