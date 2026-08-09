#!/bin/bash
#
# chroot.sh
#

################################################################################

if [[ -v __CHROOT__ ]]; then
    return
fi

declare -r __CHROOT__="chroot.sh"

################################################################################

### libraries
LIBDIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1; pwd -P)"
. "$LIBDIR"/log.sh

### constants & variables
declare -r CHROOT_PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:/opt/bin:/opt/sbin"

chroot_dir=""
chroot_active_mounts=()

### functions
_chroot_debug() {
    debug "${1:-}" "${BASH_SOURCE[0]##*/}"
}
_chroot_info () {
    info "${1:-}" "${BASH_SOURCE[0]##*/}"
}
_chroot_warn() {
    warn "${1:-}" "${BASH_SOURCE[0]##*/}"
}
_chroot_error() {
    error "${1:-}" 0 "${BASH_SOURCE[0]##*/}"
}

_chroot_mount() {
    mount -v "$@" >&2
    chroot_active_mounts=("${@: -1}" "${chroot_active_mounts[@]}")
}

_mount_resolv_conf() {
    if [[ ! -e /etc/resolv.conf ]]; then
        _chroot_error "Host /etc/resolv.conf does not exist"
        return 1
    fi

    local _source
    _source=$(realpath -e -- /etc/resolv.conf) || return 1
    if [[ ! -f "$_source" ]]; then
        _chroot_error "Host /etc/resolv.conf is not a regular file"
        return 1
    fi

    local _root _target _link
    _root=$(realpath -e -- "$chroot_dir") || return 1
    _target="$_root/etc/resolv.conf"

    if [[ -L "$_target" ]]; then
        _link=$(readlink -- "$_target") || return 1
        if [[ "$_link" == /* ]]; then
            _target="$_root$_link"
        else
            _target="$_root/etc/$_link"
        fi
        _target=$(realpath -m -s -- "$_target") || return 1

        if [[ "$_target" != "$_root"/* ]]; then
            _chroot_error "Target /etc/resolv.conf points outside the rootfs"
            return 1
        fi
    fi

    if [[ -L "$_target" ]]; then
        _chroot_error "Target /etc/resolv.conf contains a symbolic link chain"
        return 1
    fi
    if [[ ! -e "$_target" ]]; then
        install -Dm644 /dev/null "$_target"
    fi

    _chroot_info "Mounting host /etc/resolv.conf onto \"$_target\""
    _chroot_mount --bind "$_source" "$_target"
}

# chroot_setup <chroot_dir>
# $1: the directory to chroot into
# when using `chroot_setup`, `chroot_teardown` must be call to clean up
# for example, `trap chroot_teardown EXIT`
chroot_setup() {
    if [[ -n "$chroot_dir" ]]; then
        _chroot_error "\"chroot_dir\" is already set to \"$chroot_dir\""
        return 1
    fi

    local _chroot_dir="$1"

    if ! mountpoint -q "$_chroot_dir"; then
        _chroot_error "\"$_chroot_dir\" is not a mountpoint"
        _chroot_error "Please run \`mount --bind $_chroot_dir $_chroot_dir\`"
        return 1
    fi

    chroot_dir="$_chroot_dir"

    _chroot_debug "Setting up chroot environment in \"$chroot_dir\""

    _chroot_mount -t proc       -o rw,nosuid,nodev,noexec                       proc        "$chroot_dir/proc"
    _chroot_mount -t sysfs      -o ro,nosuid,nodev,noexec                       sysfs       "$chroot_dir/sys"
    _chroot_mount -t efivarfs   -o rw,nosuid,nodev,noexec                       efivarfs    "$chroot_dir/sys/firmware/efi/efivars"
    _chroot_mount -t devtmpfs   -o rw                                           devtmpfs    "$chroot_dir/dev"
    _chroot_mount -t devpts     -o rw,nosuid,noexec,gid=5,mode=620,ptmxmode=000 devpts      "$chroot_dir/dev/pts"
    _chroot_mount -t tmpfs      -o rw,nosuid,nodev                              tmpfs       "$chroot_dir/dev/shm"
    _chroot_mount -t tmpfs      -o rw,nosuid,nodev,mode=755                     tmpfs       "$chroot_dir/run"

    _mount_resolv_conf

    _chroot_debug "Done (setup)"
}

chroot_teardown() {
    local _mountpoints=()

    if [[ -z "$chroot_dir" ]] || (( ${#chroot_active_mounts[@]} == 0 )); then
        _chroot_debug "\"chroot_dir\" is not set, nothing to tear down"
        return
    fi

    _chroot_debug "Tearing down chroot environment in \"$chroot_dir\""

    while (( ${#chroot_active_mounts[@]} > 0 )); do
        local _mp
        for _mp in "${chroot_active_mounts[@]}"; do
            if mountpoint -q "$_mp" >&2; then
                if ! umount -v "$_mp"; then
                    _mountpoints+=("$_mp")
                    _chroot_warn "Failed to unmount \"$_mp\", retry later"
                fi
            else
                _chroot_debug "Mountpoint \"$_mp\" is not mounted, skipping"
            fi
        done
        chroot_active_mounts=("${_mountpoints[@]}")
        _mountpoints=()
        sleep 3
    done

    _chroot_debug "Done (teardown)"
}

chroot_run() {
    SHELL=/bin/bash PATH="$CHROOT_PATH" LC_ALL=C chroot "$@"
}

chroot_pid_unshare_run() {
    SHELL=/bin/bash PATH="$CHROOT_PATH" LC_ALL=C unshare --fork --pid chroot "$@"
}

debug "${BASH_SOURCE[0]} sourced"
