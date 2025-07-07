#!/bin/bash
#
# install.pc.sh
#

################################################################################

if [[ -v __INSTALL_LIVEOS__ ]]; then
    return
fi

declare -r __INSTALL_LIVEOS__="install.liveos.sh"

################################################################################

### constants and variables (before argument processing)
declare -r ISO_LABEL="LIVEOS"

declare -ar COMMON_DEB_PKGS=(
    ### general
    nano
    bash-completion
    zsh
    zsh-syntax-highlighting
    zsh-autosuggestions
    ### disk
    parted fdisk
    smartmontools
    ### filesystem
    dosfstools
    e2fsprogs
    xfsprogs
    btrfs-progs
    # bcachefs-tools
    ### network
    iw wpasupplicant
    wget curl
    openssh-server
    git
    ### kernel
    linux-image-generic
    # dracut
    initramfs-tools
    efibootmgr
    ### pacman
    libarchive-tools
    zstd
    libgpgme-dev
)
declare -ar JAMMY_DEB_PKGS=()
declare -ar NOBLE_DEB_PKGS=(
    systemd-boot
    systemd-resolved
)
declare -ar QUESTING_DEB_PKGS=(
    systemd-boot
    systemd-boot-efi
    systemd-resolved
)
declare -ar UBUNTU_PACMAN_PKGS=(
    pacman
    linux
    debootstrap
)
declare -ar KZL_PACMAN_PKGS=(
    base
    linux
)

deb_pkgs=("${COMMON_DEB_PKGS[@]}")
pacman_pkgs=()

declare -r KZL_LINUX_CONF=$(cat << EOF
title   KZL Linux
linux   /vmlinuz
#initrd  /initramfs.img
options root=live:CDLABEL=$ISO_LABEL rd.live.overlay.overlayfs rd.live.image rd.shell
EOF
)
declare -r UBUNTU_KZL_CONF=$(cat << EOF
title   Ubuntu-KZL
linux   /vmlinuz-KZL
initrd  /initramfs-KZL.img
options root=live:CDLABEL=$ISO_LABEL rd.live.overlay.overlayfs rd.live.image rd.shell
EOF
)
declare -r UBUNTU_CONF=$(cat << EOF
title   Ubuntu
linux   /vmlinuz
initrd  /initramfs.img
options root=live:CDLABEL=$ISO_LABEL rd.live.overlay.overlayfs rd.live.image rd.shell
EOF
)
efi_dir=""
default_efi_entry=""
declare -A efi_boot_entries=()

################################################################################

pacman_pkgs=("${UBUNTU_PACMAN_PKGS[@]}")
efi_dir="boot/efi"
default_efi_entry="ubuntu-kzl.conf"
efi_boot_entries=(
    ["ubuntu-kzl.conf"]="$UBUNTU_KZL_CONF"
    ["ubuntu.conf"]="$UBUNTU_CONF"
)
case "$arg_suite" in
    jammy)
        deb_pkgs+=("${JAMMY_DEB_PKGS[@]}")
        ;;
    noble)
        deb_pkgs+=("${NOBLE_DEB_PKGS[@]}")
        ;;
    questing)
        deb_pkgs+=("${QUESTING_DEB_PKGS[@]}")
        ;;
    kzl)
        pacman_pkgs=("${KZL_PACMAN_PKGS[@]}")
        efi_dir="boot"
        default_efi_entry="kzl-linux.conf"
        efi_boot_entries=(
            ["kzl-linux.conf"]="$KZL_LINUX_CONF"
        )
        ;;
    *)
        error "Unsupported suite \"$arg_suite\"" 128
        ;;
esac
readonly -a deb_pkgs
readonly -a pacman_pkgs
readonly efi_dir
readonly default_efi_entry
readonly -A efi_boot_entries

################################################################################

### constants and variables (after argument processing)
declare -r HOSTNAME="LiveOS"
declare -r ISO_NAME="${distro^}-$arg_suite"
declare -r ISO_PUBLISHER="<https://github.com/lz3450/LFS>"
declare -r ISO_APPLICATION="Live/Rescue ISO Image"

declare -r ISOFS_DIR="$WORK_DIR/iso"
declare -r RO_ROOTFS_IMG_DIR="$ISOFS_DIR/LiveOS"
declare -r RO_ROOTFS_IMG_FILE_NAME="squashfs.img"
declare -r RO_ROOTFS_IMG_FILE_PATH="$RO_ROOTFS_IMG_DIR/$RO_ROOTFS_IMG_FILE_NAME"
declare -r PACMAN_REPO_DIR="home/.repository/ubuntu"
declare -r PACMAN_REPO_FILE="$PACMAN_REPO_DIR/ubuntu.db.tar.zst"
declare -r ISO_FILE_NAME="liveos-$arg_suite-$TIMESTAMP.iso"

### libraries
LIBDIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1; pwd -P)"
. "$LIBDIR/chroot.sh"
. "$SCRIPT_DIR/lib/pacman.sh"

### functions
prepare_rootfs() {
    exec 3>&1
    exec > "$LOG_DIR/${FUNCNAME[0]}.log"

    # mkpart
    parted -s "$loop_device" \
        mklabel gpt \
        unit s \
        mkpart BOOT fat32 2048 524287 \
        mkpart "$ISO_LABEL" ext4 524288 4718591 \
        mkpart HOME ext4 4718592 100% \
        set 1 esp on \
        print

    # mkfs
    mkfs.fat -F 32 -n BOOT -- "${loop_device}p1"
    mkfs.ext4 -L "$ISO_LABEL" -- "${loop_device}p2" 2>&1
    mkfs.ext4 -L HOME -- "${loop_device}p3" 2>&1

    # mount
    mkdir -p -- "$ISOFS_DIR"
    mount -o "$MOUNT_OPT" -- "${loop_device}p2" "$ISOFS_DIR"

    exec 1>&3 3>&-
}

post_install_pkgs() {
    delete_all_contents "$ROOTFS_DIR/boot/efi/"
    delete_all_contents "$ROOTFS_DIR/home"


    mount -o "$MOUNT_OPT,umask=0177" -- "${loop_device}p1" "$ROOTFS_DIR/$efi_dir"
    mountpoint -q -- "$ROOTFS_DIR/$efi_dir" || error "/$efi_dir not mounted" 2
    mount -o "$MOUNT_OPT" -- "${loop_device}p3" "$ROOTFS_DIR/home"
    mountpoint -q -- "$ROOTFS_DIR/home" || error "/home not mounted" 2

    touch -- "$ISOFS_DIR/$TIMESTAMP"
    cp -vf -- "$INSTALLED_DEB_PKGLIST_FILE" "$ISOFS_DIR/deb_pkgs.txt"
    cp -vf -- "$INSTALLED_PACMAN_PKGLIST_FILE" "$ISOFS_DIR/pacman_pkgs.txt"
}

_make_initramfs_for_kernel() {
    local _kernel_version="$1"
    local _kernel_image="$2"
    local _kmoddir="$3"

    debug "Making initramfs for kernel $_kernel_version"
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
}

_get_kernel_suffix() {
    local _kernel_version="$1"
    case "-${_kernel_version##*-}" in
        -generic) echo "" ;;
        -KZL) echo "-KZL" ;;
        *) echo ""; warn "Unknown kernel version: $_kernel_version" ;;
    esac
}

configure_rootfs_platform_specific() {
    ### 1. general
    # shadow
    sed -i 's/^root:[^:]*:/root::/' "$ROOTFS_DIR"/etc/shadow
    # issue and motd
    cat > "$ROOTFS_DIR"/etc/issue << EOF
$ISO_NAME Live OS \n (\s \m \r) \t \l

EOF
    mkdir -p -- "$ROOTFS_DIR"/etc/issue.d
    cat > "$ROOTFS_DIR"/etc/issue.d/00-ip.issue << EOF

IPv4 address: \4
IPv6 address: \6

EOF
    cat > "$ROOTFS_DIR"/etc/motd << EOF
Welcome to $ISO_NAME Live OS!

EOF
    # fstab
    cat > "$ROOTFS_DIR"/etc/fstab << EOF
LABEL=HOME      /home       ext4        $MOUNT_OPT,nofail       0 2
EOF
    # ssh
    sed -i \
        -e '/X11Forwarding/c\#X11Forwarding yes' \
        -e '/PermitRootLogin/c\PermitRootLogin yes' \
        -e '/PermitEmptyPasswords/c\PermitEmptyPasswords yes' \
        "$ROOTFS_DIR/etc/ssh/sshd_config"
    mkdir -p -- "$CONFIG_DIR/liveos"
    cp -vf -- "$ROOTFS_DIR/etc/ssh/sshd_config" "$CONFIG_DIR/liveos/sshd_config"
    chown ${SUDO_UID:-0}:${SUDO_GID:-0} "$CONFIG_DIR/liveos/sshd_config"
    # systemd
    local _ssh_service="sshd.service"
    if [[ "$distro" == "ubuntu" ]]; then
        _ssh_service="ssh.service"
    fi
    chroot_setup "$ROOTFS_DIR"
    chroot_run "$ROOTFS_DIR" /bin/bash -e -u -o pipefail -s << EOF
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service
systemctl enable $_ssh_service
EOF
    chroot_teardown

    ### 2. pacman repository
    info "Setting up pacman repository for LiveOS..."
    mkdir -p -- "$ROOTFS_DIR/$PACMAN_REPO_DIR"
    local _pkg
    local _pkg_file
    for _pkg in "${pacman_pkgs[@]}"; do
        debug "Adding $_pkg to pacman repository..."
        _pkg_file=$(pacman_get_pkg_file "$_pkg" "/$PACMAN_REPO_DIR")
        cp -f -- "/$PACMAN_REPO_DIR/$_pkg_file" "$ROOTFS_DIR/$PACMAN_REPO_DIR"
        repo-add -R "$ROOTFS_DIR/$PACMAN_REPO_FILE" "$ROOTFS_DIR/$PACMAN_REPO_DIR/$_pkg_file" > /dev/null
    done

    ### 3. efi bootloader
    info "Making initramfs for all installed kernels..."
    local _kernel_version
    for _kernel_version in $(ls "$ROOTFS_DIR"/usr/lib/modules); do
        _make_initramfs_for_kernel \
            "$_kernel_version" \
            "$ROOTFS_DIR/boot/vmlinuz-$_kernel_version" \
            "$ROOTFS_DIR/lib/modules/$_kernel_version"
    done

    info "Setting up systemd-boot for UEFI booting..."
    mkdir -p -- "$ROOTFS_DIR/$efi_dir/loader/entries"
    local _entry
    for _entry in "${!efi_boot_entries[@]}"; do
        echo "${efi_boot_entries[$_entry]}" > "$ROOTFS_DIR/$efi_dir/loader/entries/$_entry"
    done

    mkdir -p -- "$ROOTFS_DIR/$efi_dir/EFI/BOOT"
    cp -f -- "$ROOTFS_DIR/usr/lib/systemd/boot/efi/systemd-bootx64.efi" "$ROOTFS_DIR/$efi_dir/EFI/BOOT/BOOTx64.EFI"
    cat > "$ROOTFS_DIR/$efi_dir/loader/loader.conf" << EOF
timeout 30
console-mode max
default $default_efi_entry
EOF

    if [[ "$distro" != "kzl-linux" ]]; then
        local _kv
        for _kv in $(ls "$ROOTFS_DIR"/usr/lib/modules); do
            local _kernel_suffix="$(_get_kernel_suffix "$_kv")"
            debug "Copying kernel and initramfs ($_kv) to EFI file system..."
            cp -f -- "$ROOTFS_DIR"/boot/vmlinuz-$_kv "$ROOTFS_DIR/$efi_dir/vmlinuz$_kernel_suffix"
            cp -f -- "$ROOTFS_DIR"/boot/initramfs-$_kv.img "$ROOTFS_DIR/$efi_dir/initramfs$_kernel_suffix.img"
        done
    fi
}

_make_rootfs_ro_rootfs_img() {
    info "Making rootfs SquashFS/EROFS image, this may take some time..."
    local _rootfs_img_file="$SCRIPT_DIR/images/${ISO_FILE_NAME%.iso}-$RO_ROOTFS_IMG_FILE_NAME"
    # mksquashfs "$ROOTFS_DIR" "$_rootfs_img_file" -b 1M -comp zstd -noappend
    mkfs.erofs -- "$_rootfs_img_file" "$ROOTFS_DIR"
    chown ${SUDO_UID:-0}:${SUDO_GID:-0} "$_rootfs_img_file"
    mkdir -vp -- "$RO_ROOTFS_IMG_DIR"
    cp -vf -- "$_rootfs_img_file" "$RO_ROOTFS_IMG_DIR/$RO_ROOTFS_IMG_FILE_NAME"
}

_make_iso_image() {
    info "Making ISO image..."
    xorriso \
        -as mkisofs \
        -iso-level 3 \
        -joliet \
        -joliet-long \
        -full-iso9660-filenames \
        -rational-rock \
        -volid "$ISO_LABEL" \
        -publisher "$ISO_NAME $ISO_PUBLISHER" \
        -appid "$ISO_NAME $ISO_APPLICATION" \
        -preparer "prepared by kzl" \
        -partition_offset 16 \
        -append_partition 2 C12A7328-F81F-11D2-BA4B-00A0C93EC93B "$WORK_DIR/efiboot.img" \
        -append_partition 3 0FC63DAF-8483-4772-8E79-3D69D8477DE4 "$WORK_DIR/home.img" \
        -appended_part_as_gpt \
        -output "$SCRIPT_DIR/images/$ISO_FILE_NAME" \
        "$ISOFS_DIR"
    chown ${SUDO_UID:-0}:${SUDO_GID:-0} "$SCRIPT_DIR/images/$ISO_FILE_NAME"
}

post_configure_rootfs() {
    cp -a -- "$ROOTFS_DIR/$efi_dir/EFI" "$ISOFS_DIR/"

    sync

    umount -v -- "$ROOTFS_DIR/$efi_dir"
    mountpoint -q -- "$ROOTFS_DIR/$efi_dir" && error "/$efi_dir is still mounted" 2
    umount -v -- "$ROOTFS_DIR/home"
    mountpoint -q -- "$ROOTFS_DIR/home" && error "/home is still mounted" 2

    dd if="${loop_device}p1" of="$WORK_DIR/efiboot.img" bs=1M status=progress
    dd if="${loop_device}p3" of="$WORK_DIR/home.img" bs=1M status=progress

    clean_rootfs "$ROOTFS_DIR"

    _make_rootfs_ro_rootfs_img
    _make_iso_image
}

cleanup_platform_specific() {
    set +e
    chroot_teardown
}
