#!/bin/bash
#
# 00-install.sh
#

set -e
set -o pipefail
set -u
# set -x

umask 0022

SCRIPT_NAME="$(basename "$0")"
SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

################################################################################

# unset __DEBUG__
# __DEBUG__=1

### general libraries
. "$SCRIPT_DIR"/lib/log.sh
. "$SCRIPT_DIR"/lib/utils.sh
. "$SCRIPT_DIR"/lib/chroot.sh
. "$SCRIPT_DIR"/lib/deb.sh
. "$SCRIPT_DIR"/lib/pacman.sh

### checks
check_root

### constants & variables
declare -r CONFIG_DIR="$SCRIPT_DIR"/config

declare -r UBUNTU_MIRROR="http://us.archive.ubuntu.com/ubuntu/"
# UBUNTU_MIRROR="https://mirror.arizona.edu/ubuntu/"
declare -r BTRFS_SUBVOLS=(
    @home
    @var
    @log
    @cache
)
declare -r -A BTRFS_SUBVOL_MOUNTS=(
    ["@home"]="home"
    ["@var"]="var"
    ["@log"]="var/log"
    ["@cache"]="var/cache"
)
declare -r BTRFS_OPT="rw,noatime"
declare -r BTRFS_ROOT_MOUNT_OPTION="$BTRFS_OPT,compress=zstd"
declare -r -A BTRFS_SUBVOL_MOUNT_OPTIONS=(
    ["@home"]="$BTRFS_OPT,subvol=@home"
    ["@var"]="$BTRFS_OPT,subvol=@var"
    ["@log"]="$BTRFS_OPT,subvol=@log"
    ["@cache"]="$BTRFS_OPT,subvol=@cache"
)

common_deb_pkgs=(
    ### general
    sudo
    build-essential
    ### disk
    parted
    btrfs-progs
    ### network
    iw wpasupplicant
    rfkill
    ### kernel
    linux-image-generic
    # dracut
    initramfs-tools
    ### pacman
    libarchive-tools
    zstd
    libgpgme-dev
    fakeroot
)
jammy_deb_pkgs=()
noble_deb_pkgs=(
    systemd-boot
    systemd-resolved
)
questing_deb_pkgs=(
    systemd-boot
    systemd-boot-efi
    systemd-resolved
)
pacman_pkgs=(
    pacman
    linux
)

arg_rootfs_dir="/mnt"
arg_suite=""
arg_rootfs_tarball=""

log_dir=""
efi_dev=""
btrfs_dev=""
swap_dev=""
deb_pkgs=()

### functions
cleanup() {
    set +e

    log_magenta "Cleaning up..."
    chroot_teardown
    log_magenta "Done (Cleaned up)"

    trap - EXIT SIGINT SIGTERM SIGKILL
}
trap cleanup EXIT SIGINT SIGTERM SIGKILL

create_btrfs_subvols() {
    info "Creating btrfs subvolumes..."
    btrfs_dev=$(findmnt -n -o SOURCE --target "$arg_rootfs_dir")
    info "BTRFS device: $btrfs_dev"
    # @
    btrfs subvolume create "$arg_rootfs_dir"/@
    btrfs subvolume set-default "$arg_rootfs_dir"/@
    # other subvolumes
    local _subvol
    for _subvol in "${BTRFS_SUBVOLS[@]}"; do
        btrfs subvolume create "$arg_rootfs_dir"/"$_subvol"
    done
    chattr +C -- "$arg_rootfs_dir"/@cache
    btrfs subvolume list "$arg_rootfs_dir"
    # mount @
    umount -v -- "$arg_rootfs_dir"
    mount -v -o $BTRFS_ROOT_MOUNT_OPTION,subvol=@ -- "$btrfs_dev" "$arg_rootfs_dir"
    info "Done (Created btrfs subvolumes)"
}

mount_rootfs() {
    info "Mounting btrfs device..."
    local _subvol
    for _subvol in "${BTRFS_SUBVOLS[@]}"; do
        if [[ -d "$arg_rootfs_dir/${BTRFS_SUBVOL_MOUNTS[$_subvol]}" ]]; then
            error "Mount point $arg_rootfs_dir/${BTRFS_SUBVOL_MOUNTS[$_subvol]} is not empty" 1
        fi
        mkdir -vp -- "$arg_rootfs_dir/${BTRFS_SUBVOL_MOUNTS[$_subvol]}"
        mount -v -o "${BTRFS_SUBVOL_MOUNT_OPTIONS[$_subvol]}" -- "$btrfs_dev" "$arg_rootfs_dir/${BTRFS_SUBVOL_MOUNTS[$_subvol]}"
    done
    info "Done (Mounted btrfs)"

    info "Mounting efi partition..."
    if [[ -d "$arg_rootfs_dir/boot/efi" ]]; then
        error "EFI partition mount point $arg_rootfs_dir/boot/efi exists" 1
    fi
    mkdir -vp -- "$arg_rootfs_dir/boot/efi"
    chmod 0600 -- "$arg_rootfs_dir/boot/efi"

    local _answer="N"
    local _efi_dev
    while [[ "$_answer" != "Y" && "$_answer" != "y" ]]; do
        read -p "EFI partition device (e.g. /dev/sda1): " _efi_dev
        if [[ ! -b "$_efi_dev" ]]; then
            warn "Invalid EFI partition device: $_efi_dev, retry"
            continue
        fi
        read -p "Mount EFI partition $_efi_dev on $arg_rootfs_dir/boot/efi? (Y/n) " _answer
    done
    efi_dev="$_efi_dev"
    mkfs.fat -F 32 "$efi_dev"
    mount -v -o rw,noatime,umask=0177 -- "$efi_dev" "$arg_rootfs_dir/boot/efi"
    info "Done (Mounted efi partition $efi_dev at $arg_rootfs_dir/boot/efi)"
}

make_swapfile() {
    info "Creating swap file..."
    fallocate -l 16G "$arg_rootfs_dir/swapfile"
    chmod 600 "$arg_rootfs_dir/swapfile"
    mkswap "$arg_rootfs_dir/swapfile"
    info "Done (Created swap file)"
}

make_swap_partition() {
    info "Creating swap partition..."
    local _swap_dev
    local _answer="N"
    while [[ "$_answer" != "Y" && "$_answer" != "y" ]]; do
        read -p 'Device for swap partition (e.g. /dev/sda3): ' _swap_dev
        if [[ ! -b "$_swap_dev" ]]; then
            warn "Invalid swap partition device: $_swap_dev, retry"
            continue
        fi
        read -p "Create swap partition on $_swap_dev? (Y/n) " _answer
    done
    swap_dev="$_swap_dev"
    mkswap "$swap_dev"
    info "Done (Created swap partition on $swap_dev)"
}

bootstrap_rootfs() {
    info "Extracting root filesystem..."
    tar -v \
        --zstd \
        --xattrs --acls \
        --numeric-owner \
        -xpf "$arg_rootfs_tarball" \
        -C "$arg_rootfs_dir" \
        > "$log_dir/tar.log"
    info "Done (Extracted root filesystem)"

    info "Install deb packages..."
    deb_apt "$arg_rootfs_dir" deb_pkgs > "$log_dir/apt.log"
    deb_set_locale "$arg_rootfs_dir"
    deb_get_installed_pkgs "$arg_rootfs_dir" | sed -e '/^linux-image-.+/d' -e '/^linux-modules-.+/d' -e 's/:amd64//g' > "$log_dir/installed_deb_pkgs.txt"
    info "Done (Installed deb packages)"

    info "Install pacman packages..."
    pacman_bootstrap "$arg_rootfs_dir" "$arg_rootfs_dir"/home/.repository/ubuntu pacman_pkgs | tee "$log_dir"/pacman.log
    pacman_get_installed_pkgs "$arg_rootfs_dir" > "$log_dir/installed_pacman_pkgs.txt"
    info "Done (Installed pacman packages)"

    info "Cleaning up rootfs..."
    rm -vrf -- "$arg_rootfs_dir"/bin.usr-is-merged
    rm -vrf -- "$arg_rootfs_dir"/lib.usr-is-merged
    rm -vrf -- "$arg_rootfs_dir"/sbin.usr-is-merged
    info "Done (Cleaned up rootfs)"
}

configure_rootfs() {
    info "Configuring rootfs..."
    local _hostname
    # hostname
    read -p 'hostname: ' _hostname
    echo "$_hostname" > "$arg_rootfs_dir/etc/hostname"
    # environment
    echo "PATH=\"/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:/opt/bin:/opt/sbin\"" > "$arg_rootfs_dir/etc/environment"
    # passwd
    sed -i '/^root/s|/bin/bash|/bin/zsh|' "$arg_rootfs_dir"/etc/passwd
    # network
    cp -vf -- "$CONFIG_DIR/ethernet.network" "$arg_rootfs_dir/etc/systemd/network/ethernet.network"
    cp -vf -- "$CONFIG_DIR/wifi.network" "$arg_rootfs_dir/etc/systemd/network/wifi.network"
    cp -vf -- "$CONFIG_DIR/wpa_supplicant.conf" "$arg_rootfs_dir/etc/wpa_supplicant/wpa_supplicant.conf"
    ln -sf wpa_supplicant.conf "$arg_rootfs_dir/etc/wpa_supplicant/wpa_supplicant-wlan0.conf"
    # grml-zsh-config for root
    wget -qO "$arg_rootfs_dir/root/.zshrc" https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc
    echo '. /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> "$arg_rootfs_dir/root/.zshrc"
    echo '. /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh' >> "$arg_rootfs_dir/root/.zshrc"
    # fstab
    local _root______________________partuuid=$(blkid -s PARTUUID -o value "$btrfs_dev")
    local _boot______________________partuuid=$(blkid -s PARTUUID -o value "$efi_dev")
    local _swap______________________partuuid=$(blkid -s PARTUUID -o value "$swap_dev")
    cat > "$arg_rootfs_dir"/etc/fstab << EOF
# Static information about the filesystems.
# See fstab(5) for details.

# <device> <target> <type> <options> <dump> <pass>

PARTUUID=$_root______________________partuuid       /                   btrfs       $BTRFS_ROOT_MOUNT_OPTION,subvol=@       0 1
PARTUUID=$_root______________________partuuid       /home               btrfs       $BTRFS_OPT,subvol=@home                 0 1
PARTUUID=$_root______________________partuuid       /var                btrfs       $BTRFS_OPT,subvol=@var                  0 1
PARTUUID=$_root______________________partuuid       /var/log            btrfs       $BTRFS_OPT,subvol=@log                  0 1
PARTUUID=$_root______________________partuuid       /var/cache          btrfs       $BTRFS_OPT,subvol=@cache                0 1
PARTUUID=$_boot______________________partuuid       /boot/efi           vfat        rw,noatime,umask=0177                   0 2
tmpfs                                               /tmp                tmpfs       rw,nosuid,nodev,mode=1777               0 0
PARTUUID=$_swap______________________partuuid       none                swap        defaults                                0 0
EOF
    # systemd-boot
    mkdir -vp -- "$arg_rootfs_dir"/boot/efi/loader/entries
    cat > "$arg_rootfs_dir"/boot/efi/loader/loader.conf << EOF
timeout 3
console-mode max
default kzl.conf
EOF
    cat > "$arg_rootfs_dir"/boot/efi/loader/entries/ubuntu.conf << EOF
title   Ubuntu
linux   vmlinuz
initrd  initrd.img
options root=PARTUUID=$_root______________________partuuid rw rootwait
EOF
    cat > "$arg_rootfs_dir"/boot/efi/loader/entries/kzl.conf << EOF
title   Ubuntu-KZL
linux   vmlinuz-KZL
#initrd  initrd-KZL.img
options root=PARTUUID=$_root______________________partuuid rw rootwait
EOF
    # initialize.sh
    cat > "$arg_rootfs_dir"/root/initialize.sh << EOF
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
    chmod +x "$arg_rootfs_dir"/root/initialize.sh
    chroot_setup "$arg_rootfs_dir"
    chroot_run "$arg_rootfs_dir" /root/initialize.sh
    chroot_teardown
}

usage() {
    cat << EOF

Usage: $SCRIPT_NAME -h | --help
Usage: $SCRIPT_NAME [-v | --verbose ] -i | --input <arg>

    -h, --help                      print this help message and exit
    -r, --rootfs-dir <dir>          set rootfs directory (default: /mnt)
    -s, --suite <suite>             set iso suite (jammy, noble, questing)
    -t, --rootfs-tarball <file>     set rootfs tarball

EOF
}

################################################################################

while (( $# > 0 )); do
    case "$1" in
    -h | --help)
        usage
        exit
        ;;
    -r | --rootfs-dir)
        shift
        arg_rootfs_dir="$1"
        ;;
    -s | --suite)
        shift
        arg_suite="$1"
        ;;
    -t | --rootfs-tarball)
        shift
        arg_rootfs_tarball="$1"
        ;;
    *)
        usage
        error "Unknown option: $1" 128
        ;;
    esac
    shift
done

case "$arg_suite" in
    jammy)
        deb_pkgs=("${common_deb_pkgs[@]} ${jammy_deb_pkgs[@]}")
        ;;
    noble)
        deb_pkgs=("${common_deb_pkgs[@]}" "${noble_deb_pkgs[@]}")
        ;;
    questing)
        deb_pkgs=("${common_deb_pkgs[@]}" "${questing_deb_pkgs[@]}")
        ;;
    *)
        error "Unknown suite \"$arg_suite\"" 128
        ;;
esac

log_dir="$SCRIPT_DIR/log/$arg_suite"

################################################################################

prologue
mkdir -vp -- "$log_dir"
create_btrfs_subvols
mount_rootfs
make_swap_partition
bootstrap_rootfs
configure_rootfs

log_cyan "Successfully installed Ubuntu $arg_suite at $arg_rootfs_dir"

cleanup
epilogue

### error codes
# 1: general error
# 127: command not found
# 128: unknown option or invalid argument
