#!/bin/bash
#
# install-pc.sh
#

################################################################################

if [[ -v __INSTALL_PC__ ]]; then
    return
fi

declare -r __INSTALL_PC__="install-pc.sh"

################################################################################

### constants
declare -r BTRFS_SUBVOLS=(
    @home
    @var
    @log
    @cache
    @snapshots
)
declare -r -A BTRFS_SUBVOL_TARGET_DIR=(
    ["@home"]="home"
    ["@var"]="var"
    ["@log"]="var/log"
    ["@cache"]="var/cache"
    ["@snapshots"]="/.snapshots"
)
declare -r BTRFS_DEFAULT_MOUNT_OPT="$MOUNT_OPT,compress=zstd"
declare -r -A BTRFS_SUBVOL_MOUNT_OPT=(
    ["@home"]="$MOUNT_OPT,subvol=@home"
    ["@var"]="$MOUNT_OPT,subvol=@var"
    ["@log"]="$MOUNT_OPT,subvol=@log"
    ["@cache"]="$MOUNT_OPT,subvol=@cache"
    ["@snapshots"]="$MOUNT_OPT,subvol=@snapshots"
)

### libraries
LIBDIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1; pwd -P)"
. "$LIBDIR/chroot.sh"

### functions
prepare_rootfs() {
    # exec 3>&1
    # exec > "$LOG_DIR/{FUNCNAME[0]}.log"
    info "Preparing root filesystem on $loop_device..."

    # mkpart
    if [[ "$arg_device" == "loop" ]]; then
        parted -s "$loop_device" \
            mklabel gpt \
            mkpart BOOT 2048s 1048575s \
            mkpart RECOVERY 1048576s 5242879s \
            mkpart ROOT 5242580s 100% \
            set 1 esp on \
            print
    else
        local _size=$(blockdev --getsz "$loop_device")
        # 32GiB swap partition
        local _root_end=$(( (_size - 67108864) / 2048 * 2048 ))
        parted -s "$loop_device" \
            mklabel gpt \
            mkpart BOOT 2048s 1048575s \
            mkpart RECOVERY 1048576s 5242879s \
            mkpart ROOT 5242580s $(( _root_end - 1 )) \
            mkpart SWAP $_root_end 100% \
            set 1 esp on \
            print
    fi

    # mkfs
    mkfs.fat -F 32 -n "BOOT" -- "${loop_device}p1"
    mkfs.ext4 -L "RECOVERY" -- "${loop_device}p2"
    "mkfs.$rootfs_type" -L "ROOT" -- "${loop_device}p3"

    # mount
    mount -o "$MOUNT_OPT" -- "${loop_device}p3" "$ROOTFS_DIR"
    if [[ "$rootfs_type" == "btrfs" ]]; then
        debug "Creating btrfs subvolumes on $ROOTFS_DIR..."
        # @
        btrfs subvolume create "$ROOTFS_DIR/@"
        btrfs subvolume set-default "$ROOTFS_DIR/@"
        # other subvolumes
        local _subvol
        for _subvol in "${INSTALL_BTRFS_SUBVOLS[@]}"; do
            btrfs subvolume create "$ROOTFS_DIR/$_subvol"
        done
        chattr +C -- "$ROOTFS_DIR/@cache"
        btrfs subvolume list "$ROOTFS_DIR"

        debug "Mounting btrfs subvolumes on $ROOTFS_DIR..."
        # mount @
        umount -v -- "$ROOTFS_DIR"
        mount -v -o $BTRFS_DEFAULT_MOUNT_OPT,subvol=@ -- "${loop_device}p3" "$ROOTFS_DIR"
        local _subvol
        for _subvol in "${BTRFS_SUBVOLS[@]}"; do
            if [[ -d "$ROOTFS_DIR/${BTRFS_SUBVOL_TARGET_DIR[$_subvol]}" ]]; then
                error "Mount target directory $ROOTFS_DIR/${BTRFS_SUBVOL_TARGET_DIR[$_subvol]} already exists" 1
            fi
            mkdir -vp -- "$ROOTFS_DIR/${BTRFS_SUBVOL_TARGET_DIR[$_subvol]}"
            mount -v -o "${BTRFS_SUBVOL_MOUNT_OPT[$_subvol]}" -- "${loop_device}p3" "$ROOTFS_DIR/${BTRFS_SUBVOL_TARGET_DIR[$_subvol]}"
        done
    fi
    mkdir -vp -- "$ROOTFS_DIR"/boot/efi
    mount -o "$MOUNT_OPT,umask=0177" -- "${loop_device}p1" "$ROOTFS_DIR"/boot/efi

    # exec 1>&3 3>&-
}

pre_install_pkgs() {
    :
}

install_pacman_pkgs() {
    local _pacman_pkgs_installed="$PKGLIST_DIR/$arg_platform-$arg_suite-pacman-pkgs.txt"
    sudo -u "${SUDO_USER:-root}" touch -- "$_pacman_pkgs_installed"

    info "Install pacman packages..."
    pacman_bootstrap "$ROOTFS_DIR" "$ROOTFS_DIR/home/.repository/$distro" pacman_pkgs
    pacman_get_installed_pkgs "$ROOTFS_DIR" > "$_pacman_pkgs_installed"
}

post_install_pkgs() {
    :
}

configure_rootfs_platform_specific() {
    # fstab
    local _root______________________partuuid=$(blkid -s PARTUUID -o value "${loop_device}p3")
    local _boot______________________partuuid=$(blkid -s PARTUUID -o value "${loop_device}p1")
    local _swap______________________partuuid=$(blkid -s PARTUUID -o value "${loop_device}p4")
    cat > "$ROOTFS_DIR"/etc/fstab << EOF
# Static information about the filesystems.
# See fstab(5) for details.

# <device> <target> <type> <options> <dump> <pass>

PARTUUID=$_root______________________partuuid       /                   btrfs       $BTRFS_DEFAULT_MOUNT_OPT,subvol=@       0 1
PARTUUID=$_root______________________partuuid       /home               btrfs       $MOUNT_OPT,subvol=@home                 0 1
PARTUUID=$_root______________________partuuid       /var                btrfs       $MOUNT_OPT,subvol=@var                  0 1
PARTUUID=$_root______________________partuuid       /var/log            btrfs       $MOUNT_OPT,subvol=@log                  0 1
PARTUUID=$_root______________________partuuid       /var/cache          btrfs       $MOUNT_OPT,subvol=@cache                0 1
PARTUUID=$_root______________________partuuid       /.snapshots         btrfs       $MOUNT_OPT,subvol=@snapshots            0 1
PARTUUID=$_boot______________________partuuid       /boot/efi           vfat        $MOUNT_OPT,umask=0177                   0 2
tmpfs                                               /tmp                tmpfs       rw,nosuid,nodev,mode=1777               0 0
PARTUUID=$_swap______________________partuuid       none                swap        defaults                                0 0
EOF
    # systemd-boot
    mkdir -vp -- "$ROOTFS_DIR"/boot/efi/loader/entries
    cat > "$ROOTFS_DIR"/boot/efi/loader/loader.conf << EOF
timeout 3
console-mode max
default kzl.conf
EOF
    cat > "$ROOTFS_DIR"/boot/efi/loader/entries/ubuntu.conf << EOF
title   Ubuntu
linux   vmlinuz
initrd  initrd.img
options root=PARTUUID=$_root______________________partuuid rw rootwait
EOF
    cat > "$ROOTFS_DIR"/boot/efi/loader/entries/kzl.conf << EOF
title   Ubuntu-KZL
linux   vmlinuz-KZL
#initrd  initrd-KZL.img
options root=PARTUUID=$_root______________________partuuid rw rootwait
EOF
    cat > "$ROOTFS_DIR"/boot/efi/loader/entries/recovery.conf << EOF
title   Recovery
linux   vmlinuz-LiveOS
initrd  initrd-LiveOS.img
options root=PARTUUID=$_root______________________partuuid rd.live.overlay.overlayfs rd.live.image rd.shell
EOF
    # initialize.sh
    cat > "$ROOTFS_DIR"/root/initialize.sh << EOF
#!/bin/bash

set +e

echo "Setting root password..."
passwd

useradd -m -U -G adm,sudo -s /bin/zsh kzl
echo "Setting kzl password..."
passwd kzl

systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service

bootctl install --esp-path=/boot/efi
EOF
    chmod +x "$ROOTFS_DIR"/root/initialize.sh
    chroot_setup "$ROOTFS_DIR"
    chroot_run "$ROOTFS_DIR" /root/initialize.sh
    local _answer="N"
    read -p "Do you want to configure rootfs manually? (Y/n)" _answer
    if [[ "$_answer" == "Y" && "$_answer" == "y" ]]; then
        chroot_run "$ROOTFS_DIR" /bin/zsh
    fi
    chroot_teardown
}

cleanup_platform_specific() {
    set +e
    chroot_teardown
}

debug "${BASH_SOURCE[0]} sourced"
