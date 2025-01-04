#!/usr/bin/bash
#
# lib/chroot.sh
#

################################################################################

if [[ -n "${__CHROOT__:-}" ]]; then
    return
fi

declare -i __CHROOT__=1

################################################################################

### libraries
source "$(dirname ${BASH_SOURCE[0]})"/log.sh
source "$(dirname ${BASH_SOURCE[0]})"/utils.sh

### checks
check_root

### constants & variables
CHROOT_PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"

chroot_active_mounts=()
chroot_dir=""

### functions
_add_mount() {
    mount -v "$@"
    chroot_active_mounts=(${@: -1} "${chroot_active_mounts[@]}")
}

# chroot_setup <chroot_dir>
# when using `chroot_setup`, `chroot_teardown` must be call to clean up
# for example, `trap chroot_teardown EXIT`
chroot_setup() {
    chroot_active_mounts=()
    local _chroot_dir="$1"
    chroot_dir="$_chroot_dir"

    if ! mountpoint -q "$_chroot_dir"; then
        info "\"$_chroot_dir\" is not a mountpoint. This may have undesirable side effects."
        info "Bind mounting \"$_chroot_dir\" to itself."
        _add_mount --bind "$_chroot_dir" "$_chroot_dir"
    fi

    _add_mount -t sysfs -o ro,nosuid,nodev,noexec sys "$_chroot_dir/sys"
    _add_mount -t proc -o nosuid,nodev,noexec proc "$_chroot_dir/proc"
    _add_mount -t devtmpfs -o nosuid,mode=755 udev "$_chroot_dir/dev"
    _add_mount -t devpts -o nosuid,noexec,gid=5,mode=620,ptmxmode=000 devpts "$_chroot_dir/dev/pts"
    _add_mount -t tmpfs -o nosuid,nodev,noexec,mode=755 run "$_chroot_dir/run"
    _add_mount -t tmpfs -o nosuid,nodev shm "$_chroot_dir/dev/shm"
    _add_mount -t tmpfs -o nosuid,nodev,mode=1777 tmp "$_chroot_dir/tmp"
    if [[ -d "$_chroot_dir/sys/firmware/efi/efivars" ]]; then
        _add_mount -t efivarfs -o nosuid,nodev,noexec efivarfs "$_chroot_dir/sys/firmware/efi/efivars"
    fi

    if [[ -f "$_chroot_dir/etc/resolv.conf" || -L "$_chroot_dir/etc/resolv.conf" ]]; then
        mv -v -- "$_chroot_dir"/etc/resolv.conf "$_chroot_dir"/etc/resolv.conf.backup
    fi
    cp -v --dereference /etc/resolv.conf "$_chroot_dir"/etc/resolv.conf
}

chroot_teardown() {
    if (( ${#chroot_active_mounts[@]} )); then
        umount -v "${chroot_active_mounts[@]}"
    fi
    chroot_active_mounts=()

    rm -vf -- "$_chroot_dir"/etc/resolv.conf
    if [[ -f "$_chroot_dir/etc/resolv.conf.backup" || -L "$_chroot_dir/etc/resolv.conf.backup" ]]; then
        mv -v -- "$_chroot_dir"/etc/resolv.conf.backup "$_chroot_dir"/etc/resolv.conf
    fi
}

chroot_run() {
    SHELL=/bin/bash LC_ALL=C PATH="$CHROOT_PATH" unshare --fork --pid chroot "$@"
}

debug "${BASH_SOURCE[0]} sourced"

### error codes
# 1: This script must be run as root
