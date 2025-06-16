#!/bin/bash
#
# mkiso.sh
#

################################################################################

if [[ -v __LIBMKISO__ ]]; then
    return
fi

declare -r __LIBMKISO__=1

################################################################################

### checks
if [[ -z "$DISTRO" ]]; then
    error "DISTRO unbound" 2
fi

if [[ -z "$ISO_NAME" ]]; then
    error "ISO_NAME unbound" 2
fi

if [[ -z "$PACMAN_REPO_DIR" ]]; then
    error "PACMAN_REPO_DIR unbound" 2
fi

if [[ -z "$PACMAN_REPO_FILE" ]]; then
    error "PACMAN_REPO_FILE unbound" 2
fi

if [[ -z "$opt_no_update_rootfs" ]]; then
    error "opt_no_update_rootfs unbound" 2
fi

if [[ -z "$arg_mutable_image_type" ]]; then
    error "arg_mutable_image_type unbound" 2
fi

### libraries
. log.sh
. utils.sh
. chroot.sh
. pacman.sh

### constants & variables
WORK_DIR="/tmp/mkiso-$DISTRO"
ROOTFS_DIR="$WORK_DIR/rootfs"
ISOFS_DIR="$WORK_DIR/iso"
INSTALL_DIR="LiveOS"
LOG_DIR="$WORK_DIR/log"
OUT_DIR="$SCRIPT_DIR"
MUTABLE_IMG="$WORK_DIR/mutable.img"
EFIBOOT_IMG="$WORK_DIR/efiboot.img"

# should not be changed
ISO_LABEL="LIVEOS"
ISO_PUBLISHER="$ISO_NAME <https://github.com/lz3450/LFS>"
ISO_APPLICATION="$ISO_NAME Live/Rescue ISO Image"

DRACUT_ARGUMENTS=(
)

FSTAB_ROW_FORMAT="%s\t\t%s\t\t%s\t%s\t\t%s %s\n"

### functions
create_work_dirs() {
    info "Create working directory..."
    if [[ -d "$WORK_DIR" ]]; then
        read -p "Working directory exists. Do you want to delete it? (Y/n) " answer
        if [[ -z "$answer" || "$answer" == "Y" || "$answer" == "y" ]]; then
            libmkiso_clean
            rm -rf -- "$WORK_DIR"
        fi
    fi
    mkdir -p -- "$WORK_DIR"
    mkdir -p -- "$ROOTFS_DIR"
    mkdir -p -- "$LOG_DIR"
    mkdir -p -- "$ISOFS_DIR/$INSTALL_DIR"
    # Write build date to file
    echo "$(date '+%Y/%m/%d %H:%M:%S')" > "$ISOFS_DIR/build_time.txt"
    info "Done (Create working directory)"
}

make_rootfs() {
    # Copy custom root file system files.
    if [[ -d "$SCRIPT_DIR/rootfs" ]]; then
        if (( "$opt_no_update_rootfs" == 0 )); then
            info "Update custom rootfs files..."
            sudo -u ${SUDO_USER:-root} "$SCRIPT_DIR"/update-rootfs > "$LOG_DIR"/rootfs_update.log 2>&1 || error "Failed to update rootfs" 3
            info "Done (Update custom rootfs files)"
        fi
        info "Copying custom rootfs files..."
        cp -af --no-preserve=ownership,mode -- "$SCRIPT_DIR"/rootfs/. "$ROOTFS_DIR"/
        # Set ownership and mode for files and directories
        chown -fh -- 0:0 "$ROOTFS_DIR"/etc/shadow
        chmod -f -- 400 "$ROOTFS_DIR"/etc/shadow
        chown -fhR -- 0:0 "$ROOTFS_DIR"/root
        #chmod -fR -- 640 "$ROOTFS_DIR"/root
        info "Done (Copying custom rootfs files)"
    fi
}

pacstrap_rootfs() {
    local _pkg_list=("$@")

    # info "Pacstrapping \"$ROOTFS_DIR/\": ${_pkg_list[*]}"
    # pacstrap -c -G -M -- "$ROOTFS_DIR" "${_pkg_list[@]}" >"$LOG_DIR"/pacstrap.log 2>&1 || error "Failed to pacstrap packages" 5
    # info "Done (Pacstrapping)"

    info "Pacstrapping \"$ROOTFS_DIR/\": ${_pkg_list[*]}"
    local _pacman_config
    local _tmp_conf_file="$(mktemp -t pacman.conf.XXXX)"

    if [[ $(which pacman) =~ ^/usr/bin/pacman$ ]]; then
        _pacman_config="/etc/pacman.conf"
    elif [[ $(which pacman) =~ ^/opt/bin/pacman$ ]]; then
        _pacman_config="/opt/etc/pacman.conf"
    else
        error "pacman not in standard location" 5
    fi
    cp -v "$_pacman_config" "$_tmp_conf_file"
    sed -i 's/^DownloadUser/#&/' "$_tmp_conf_file"
    _pacman_config="$_tmp_conf_file"

    mkdir -vp -m 0755 -- "$ROOTFS_DIR"/{dev,run,etc/pacman.d}
    mkdir -vp -m 0755 -- "$ROOTFS_DIR"/var/{cache/pacman/pkg,lib/pacman,log}
    mkdir -vp -m 1777 -- "$ROOTFS_DIR"/tmp
    mkdir -vp -m 0555 -- "$ROOTFS_DIR"/{sys,proc}
    chroot_setup "$ROOTFS_DIR" || error "Failed to install pacman packages" 5
    unshare --fork --pid \
        pacman -Sy \
        -r "$ROOTFS_DIR" \
        --cachedir "/$PACMAN_REPO_DIR" \
        --config "$_pacman_config" \
        --disable-sandbox \
        --noconfirm \
        "${_pkg_list[@]}" \
        2>&1 | tee "$LOG_DIR"/pacman.log || error "Failed to install pacman packages" 5
    chroot_teardown || error "Failed to install pacman packages" 5
    info "Done (Pacstrapping)"

    info "Creating a list of installed pacman packages..."
    pacman -Q --sysroot "$ROOTFS_DIR" > "$ISOFS_DIR"/pacman_pkglist.txt 2> /dev/null || warn "Failed to creating a list of installed pacman packages"
    info "Done (Creating a list of installed pacman packages)"
}

make_mutable_img() {
    local _size="${1:-128M}"

    info "Creating mutable image \"$MUTABLE_IMG\"..."
    rm -f -- "$MUTABLE_IMG"
    fallocate -l "$_size" "$MUTABLE_IMG"
    mkfs -t "$arg_mutable_image_type" -f -l MUTABLE "$MUTABLE_IMG" > "$LOG_DIR"/mkfs-mutable.log 2>&1
    info "Done (Creating mutable image)"
}

setup_pacman_repo() {
    local _pkg_list=("$@")

    info "Setting up pacman repository to the ISO file system..."
    mount -t "$arg_mutable_image_type" -o loop "$MUTABLE_IMG" "$ROOTFS_DIR/home"
    mkdir -p -- "$ROOTFS_DIR/$PACMAN_REPO_DIR"
    for pkg in "${_pkg_list[@]}"; do
        local _pkg_file=$(get_pkg_file "$pkg" "/$PACMAN_REPO_DIR")
        cp -vf -- "/$PACMAN_REPO_DIR/$_pkg_file" "$ROOTFS_DIR/$PACMAN_REPO_DIR"
        repo-add -R "$ROOTFS_DIR/$PACMAN_REPO_FILE" "$ROOTFS_DIR/$PACMAN_REPO_DIR/$_pkg_file" \
            > "$LOG_DIR"/pacman-repo-add.log 2>&1 \
            || error "Failed to set up pacman repository" 8
    done
    umount "$ROOTFS_DIR/home"
    info "Done (Setting up pacman repository)"
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

    info "Done (Cleaning up rootfs)"
}

make_rootfs_archive() {
    local _name="$1"
    info "Creating rootfs archive $_name..."
    tar -vcf "$OUT_DIR/$_name" \
        --transform='s|^./||' \
        --numeric-owner \
        --zstd -C "$ROOTFS_DIR" . \
        > "$LOG_DIR"/tar.log 2>&1
    chown ${SUDO_UID:-0}:${SUDO_GID:-0} "$OUT_DIR/$_name"
    info "Done (Creating rootfs archive)"
}

make_initramfs_for_kernel() {
    local _kernel_version="$1"
    local _kernel_image="$2"
    local _kmoddir="$3"

    info "Create initramfs for kernel version: $_kernel_version"
    dracut --kver "$_kernel_version" \
        --force \
        --add 'dmsquash-live overlayfs livenet pollcdrom' \
        --omit 'multipath' \
        --strip \
        --nolvmconf \
        --nomdadmconf \
        --verbose \
        --no-hostonly \
        --no-hostonly-cmdline \
        --zstd \
        --kernel-image "$_kernel_image" \
        --kmoddir "$_kmoddir" \
        "$ROOTFS_DIR/boot/initramfs-$_kernel_version.img" > "$LOG_DIR"/dracut-$_kernel_version.log 2>&1
    info "Done (Create initramfs for kernel version: $_kernel_version)"

}

make_efibootimg() {
    # Calculate the required FAT image size in bytes
    # local _imgsize=$(du -bc \
    #     "$ROOTFS_DIR/usr/lib/systemd/boot/efi/systemd-bootx64.efi" \
    #     "$SCRIPT_DIR/efiboot/loader.conf" \
    #     "$SCRIPT_DIR/efiboot/kzl-linux.conf" \
    #     "$ROOTFS_DIR/boot/vmlinuz" \
    #     "$ROOTFS_DIR/boot/initramfs.img" \
    #     2>/dev/null | awk 'END { print $1 }')
    # info "Required FAT image size $_imgsize bytes"
    # Convert from bytes to KiB and round up to the next full MiB with an additional MiB for reserved sectors.
    # local _imgsize="$(awk 'function ceil(x){return int(x)+(x>int(x))} function byte_to_kib(x){return x/1024} function mib_to_kib(x){return x*1024} END {print mib_to_kib(ceil((byte_to_kib($1)+1024)/1024))}' \
    #     <<< "$_imgsize")"
    # info "Required FAT image size $_imgsize KiB"

    local -i _imgsize=262144

    info "Creating FAT image of size: $_imgsize Byte..."
    rm -f -- "$EFIBOOT_IMG"
    mkfs.fat -C -F 32 -n "ISO_EFI" "$EFIBOOT_IMG" "$_imgsize" > /dev/null 2>&1
    info "Done (Creating FAT image)"

    info "Setting up systemd-boot for UEFI booting..."
    # Create the default/fallback boot path in which a boot loaders will be placed later.
    mmd -i "$EFIBOOT_IMG" ::/EFI ::/EFI/BOOT
    # Copy systemd-boot EFI binary to the default/fallback boot path
    mcopy -i "$EFIBOOT_IMG" \
        "$ROOTFS_DIR"/usr/lib/systemd/boot/efi/systemd-bootx64.efi \
        ::/EFI/BOOT/BOOTx64.EFI
    # Copy systemd-boot configuration files
    mmd -i "$EFIBOOT_IMG" \
        ::/loader \
        ::/loader/entries
    mcopy -i "$EFIBOOT_IMG" \
        "$SCRIPT_DIR"/efiboot/loader.conf \
        ::/loader/
    info "Done (Set up systemd-boot for UEFI booting)"
}

make_rootfs_squashfs() {
    local _image_path="$ISOFS_DIR/$INSTALL_DIR/squashfs.img"

    info "Creating rootfs SquashFS image, this may take some time..."

    # Create fstab
    printf "$FSTAB_ROW_FORMAT" \
        "LABEL=ISO_EFI" \
        "/boot" \
        "vfat" \
        "defaults" \
        "0" "2" > "$ROOTFS_DIR"/etc/fstab
    printf "$FSTAB_ROW_FORMAT" \
        "LABEL=MUTABLE" \
        "/home" \
        "$arg_mutable_image_type" \
        "defaults" \
        "0" "2" >> "$ROOTFS_DIR"/etc/fstab
    # Create a squashfs image and place it in the ISO 9660 file system.
    mkdir -p -- "$ISOFS_DIR/$INSTALL_DIR"
    # mksquashfs "$ROOTFS_DIR" "$_image_path" -b 1M -comp zstd -noappend
    mkfs.erofs -- "$_image_path" "$ROOTFS_DIR"

    info "Done (Creating rootfs SquashFS image)"
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
        -append_partition 2 'C12A7328-F81F-11D2-BA4B-00A0C93EC93B' "$EFIBOOT_IMG" \
        -append_partition 3 '0FC63DAF-8483-4772-8E79-3D69D8477DE4' "$MUTABLE_IMG" \
        -appended_part_as_gpt \
        -no-pad \
        -output "$OUT_DIR/$_name" \
        "$ISOFS_DIR/" > "$LOG_DIR"/xorriso.log 2>&1 || error "Failed to create ISO image" 7
    chown ${SUDO_UID:-0}:${SUDO_GID:-0} "$OUT_DIR/$_name"
    info "Done (Creating ISO image)"
}

mkiso_clean() {
    info "Cleaning (libmkiso)..."
    umount "$ROOTFS_DIR/home"
    chroot_teardown
    info "Done (Cleaning (libmkiso))"
}

debug "${BASH_SOURCE[0]} sourced"

### error codes
# 2: Constant or variable unbound
# 3: Failed to update rootfs
# 4: Failed to debootstrap rootfs
# 5: Failed to pacstrap packages
# 6: Failed to configure rootfs
# 7: Failed to create ISO image
# 8: Failed to set up pacman repository
# 127: Unknown option
# 255: Must be run as root
