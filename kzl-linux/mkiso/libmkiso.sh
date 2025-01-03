#!/usr/bin/bash
#
# libmkiso.sh
#

################################################################################

# requires: lib/log.sh
# requires: lib/util.sh
# requires: lib/chroot.sh

################################################################################

### checks
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root" 1
fi

if [[ -z "$DISTRO" ]]; then
    error "DISTRO is not set" 2
fi

if [[ -z "$ISO_NAME" ]]; then
    error "ISO_NAME is not set" 2
fi

### constants & variables
WORK_DIR="/tmp/$DISTRO-mkiso"
ROOTFS_DIR="$WORK_DIR"/rootfs
ISOFS_DIR="$WORK_DIR"/iso
INSTALL_DIR="LiveOS"
LOG_DIR="$WORK_DIR"/log
OUT_DIR="$SCRIPT_DIR"

ISO_LABEL="LIVEOS"
ISO_PUBLISHER="$ISO_NAME <https://github.com/lz3450/LFS>"
ISO_APPLICATION="$ISO_NAME Live/Rescue ISO Image"

DRACUT_ARGUMENTS=(
    --force
    --add 'livenet dmsquash-live convertfs pollcdrom qemu qemu-net'
    --omit 'plymouth'
    --no-early-microcode
    --strip
    --nolvmconf
    --nomdadmconf
    --verbose
    --no-hostonly
    --zstd
)

FSTAB_ROW_FORMAT="%s\t\t%s\t\t%s\t%s\t\t%s %s\n"

### functions
create_work_dir() {
    info "Create working directory..."
    if [[ -d "$WORK_DIR" ]]; then
        read -p "Working directory exists. Do you want to delete it? (Y/n) " answer
        if [[ -z "$answer" || "$answer" == "Y" || "$answer" == "y" ]]; then
            rm -rf -- "$WORK_DIR"
        fi
    fi
    mkdir -p -- "$WORK_DIR"
    info "Done"
}

make_rootfs() {
    mkdir -p -- "$ROOTFS_DIR"
    mkdir -p -- "$ISOFS_DIR/$INSTALL_DIR"
    mkdir -p -- "$LOG_DIR"

    # Write build date to file
    echo "$(date '+%Y/%m/%d %H:%M:%S')" >"$ISOFS_DIR/build_time.txt"

    # Copy custom root file system files.
    if [[ -d "$SCRIPT_DIR/rootfs" ]]; then
        if (( "$no_update_rootfs" == 0 )); then
            info "Update custom rootfs files..."
            sudo -u ${SUDO_USER:-root} "$SCRIPT_DIR"/update-rootfs >"$LOG_DIR"/rootfs_update.log 2>&1 || error "Failed to update rootfs" 3
            info "Done"
        fi
        info "Copying custom rootfs files..."
        cp -af --no-preserve=ownership,mode -- "$SCRIPT_DIR"/rootfs/. "$ROOTFS_DIR"/
        mkdir -p -- "$ROOTFS_DIR"/root/mutable
        # Set ownership and mode for files and directories
        chown -fh -- 0:0 "$ROOTFS_DIR"/etc/shadow
        chmod -f -- 400 "$ROOTFS_DIR"/etc/shadow
        chown -fhR -- 0:0 "$ROOTFS_DIR"/root
        chmod -fR -- 750 "$ROOTFS_DIR"/root
        info "Done"
    fi
}

make_rootfs_archive() {
    local _name="$1"
    info "Creating rootfs archive $_name..."

    tar --numeric-owner -cf "$OUT_DIR/$_name" \
        --zstd "$ROOTFS_DIR" >"$LOG_DIR"/tar.log 2>&1
    chown ${SUDO_UID:-0}:${SUDO_GID:-0} "$OUT_DIR/$_name"

    info "Done"
}

cleanup_rootfs() {
    info "Cleaning up rootfs..."

    # system
    # delete_all "$ROOTFS_DIR"/boot/
    delete_all "$ROOTFS_DIR"/var/tmp/
    delete_all "$ROOTFS_DIR"/tmp/
    delete_all "$ROOTFS_DIR"/var/log
    delete_all "$ROOTFS_DIR"/dev
    delete_all "$ROOTFS_DIR"/run

    # apt
    delete_all "$ROOTFS_DIR"/var/lib/apt/lists
    if [[ -d "$ROOTFS_DIR/var/cache/apt/archives" ]]; then
        find "$ROOTFS_DIR"/var/cache/apt/archives -type f -name "*.deb" -delete
    fi

    # pacman
    delete_direct_files "$ROOTFS_DIR"/var/lib/pacman
    delete_dir "$ROOTFS_DIR"/var/lib/pacman/sync
    delete_all_files "$ROOTFS_DIR"/var/cache/pacman/pkg
    find "$WORK_DIR" \( -name '*.pacnew' -o -name '*.pacsave' \) -delete

    # Create an empty /etc/machine-id
    rm -f -- "$ROOTFS_DIR/etc/machine-id"
    touch "$ROOTFS_DIR/etc/machine-id"

    info "Done"
}

make_iso_image() {
    local _name="$1"
    info "Creating ISO image..."
    xorriso \
        -as mkisofs \
        -iso-level 3 \
        -joliet \
        -joliet-long \
        -full-iso9660-filenames \
        -rational-rock \
        -volid "$ISO_LABEL" \
        -publisher "$ISO_PUBLISHER" \
        -appid "$ISO_APPLICATION" \
        -preparer "prepared by kzl" \
        -partition_offset 16 \
        -append_partition 2 'C12A7328-F81F-11D2-BA4B-00A0C93EC93B' "$WORK_DIR"/efiboot.img \
        -append_partition 3 '0FC63DAF-8483-4772-8E79-3D69D8477DE4' "$WORK_DIR"/mutable.img \
        -appended_part_as_gpt \
        -no-pad \
        -output "$OUT_DIR/$_name" \
        "$ISOFS_DIR/" >"$LOG_DIR"/xorriso.log 2>&1 || error "Failed to create ISO image" 7
    chown ${SUDO_UID:-0}:${SUDO_GID:-0} "$OUT_DIR/$_name"
    info "Done"
}
