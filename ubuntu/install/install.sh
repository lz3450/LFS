#!/bin/bash
#
# install.sh
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
CONFIG_DIR="$SCRIPT_DIR"/config

UBUNTU_MIRROR="http://us.archive.ubuntu.com/ubuntu/"
# UBUNTU_MIRROR="https://mirror.arizona.edu/ubuntu/"

common_deb_pkgs=(
    ### general
    nano
    bash-completion
    zsh zsh-autosuggestions zsh-syntax-highlighting
    build-essential
    ### disk
    parted
    ### network
    iw wpasupplicant
    openssh-server
    curl wget git
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

make_swap() {
    info "Creating swap file..."
    fallocate -l 16G "$arg_rootfs_dir/swapfile"
    chmod 600 "$arg_rootfs_dir/swapfile"
    mkswap "$arg_rootfs_dir/swapfile"
    info "Done (Created swap file)"
}

_get_partuuid() {
    local _dir="$1"
    local _partuuid
    _partuuid=$(blkid -s PARTUUID "$_dir" | sed 's|.+=\"\(.*\)\"|\1|')
    echo "$_partuuid"
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
    local _root_______________________partuuid=$(findmnt -n -o PARTUUID --target "$arg_rootfs_dir")
    local _boot_______________________partuuid=$(findmnt -n -o PARTUUID --target "$arg_rootfs_dir/boot/efi")
    cat "$arg_rootfs_dir"/etc/fstab << EOF
# Static information about the filesystems.
# See fstab(5) for details.

# <device> <target> <type> <options> <dump> <pass>

PARTUUID=$_root_______________________partuuid      /               f2fs            defaults                0 1
PARTUUID=$_boot_______________________partuuid      /boot/efi       vfat            defaults,umask=0077     0 2
/swapfile                                           none            swap            defaults                0 0

EOF
    # systemd-boot
    cat "$arg_rootfs_dir"/boot/efi/loader/loader.conf << EOF
timeout 3
console-mode max
default ubuntu.conf
EOF
    cat "$arg_rootfs_dir"/boot/efi/loader/entries/ubuntu.conf << EOF
title   Ubuntu
linux   vmlinuz
initrd  initrd.img
options root=PARTUUID=$_root_partuuid rw rootwait
EOF
    cat "$arg_rootfs_dir"/boot/efi/loader/entries/kzl.conf << EOF
title   Ubuntu-KZL
linux   vmlinuz-KZL
#initrd  initrd-KZL.img
options root=PARTUUID=$_root_partuuid rw rootwait
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
    chroot_run "$arg_rootfs_dir" /root/initialize.sh > "$log_dir/initialize.log"
    chroot_teardown
}

usage() {
    cat << EOF

Usage: $SCRIPT_NAME -h | --help
Usage: $SCRIPT_NAME [-v | --verbose ] -i | --input <arg>

    -h, --help                      print this help message and exit
    -s, --suite <suite>             set iso suite (jammy, noble, questing)
    -r, --rootfs-tarball <file>     set rootfs tarball

EOF
}

################################################################################

while (( $# > 0 )); do
    case "$1" in
    -h | --help)
        usage
        exit
        ;;
    -s | --suite)
        shift
        arg_suite="$1"
        ;;
    -r | --rootfs-tarball)
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

log_dir="$SCRIPT_DIR/logs/$arg_suite"

################################################################################

prologue
mkdir -vp -- "$log_dir"
bootstrap_rootfs
make_swap
configure_rootfs

log_cyan "Successfully installed Ubuntu $debootstrap_suite at $mountpoint"

cleanup
epilogue

### error codes
# 1: general error
# 127: command not found
# 128: unknown option or invalid argument
