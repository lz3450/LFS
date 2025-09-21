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
declare -i chroot_setup_times=0

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
    mount "$@" >&2
    chroot_active_mounts=(${@: -1} "${chroot_active_mounts[@]}")
}

_resolve_link() {
    local _target="$1"
    local _rootfs="${2:-}"

    while [[ -L "$_target" ]]; do
        _target=$(readlink -m "$_target")
        if [[ -n "$_rootfs" && "$_target" != "$_rootfs"* ]]; then
            _target="${_rootfs%/}/${_target#/}"
        fi
    done

    echo "$_target"
}

_mount_resolv_conf() {
    local _source=$(_resolve_link /etc/resolv.conf)
    local _target=$(_resolve_link "$chroot_dir/etc/resolv.conf" "$chroot_dir")

    # /etc/resolv.conf does not exist in the host system, nothing to do
    if [[ ! -e $_source ]]; then
        return
    fi

    if [[ ! -e "$_target" && -L "$chroot_dir/etc/resolv.conf" ]]; then
        install -Dm644 /dev/null "$_target"
        _chroot_mount -v -c --bind "$_source" "$_target"
    fi
}

# chroot_setup <chroot_dir>
# $1: the directory to chroot into
# when using `chroot_setup`, `chroot_teardown` must be call to clean up
# for example, `trap chroot_teardown EXIT`
chroot_setup() {
    chroot_dir="$1"

    if ! mountpoint -q "$chroot_dir"; then
        _chroot_error "\"$chroot_dir\" is not a mountpoint"
        return 1
    fi

    if (( chroot_setup_times > 0 )); then
        chroot_setup_times=$(( chroot_setup_times + 1 ))
        _chroot_debug "chroot_setup_times=$chroot_setup_times"
        return
    fi

    _chroot_debug "Setting up chroot environment in \"$chroot_dir\""

    _chroot_mount -t proc       -o rw,nosuid,nodev,noexec                       proc        "$chroot_dir/proc"
    _chroot_mount -t sysfs      -o ro,nosuid,nodev,noexec                       sysfs       "$chroot_dir/sys"
    _chroot_mount -t efivarfs   -o rw,nosuid,nodev,noexec                       efivarfs    "$chroot_dir/sys/firmware/efi/efivars"
    _chroot_mount -t devtmpfs   -o rw                                           devtmpfs    "$chroot_dir/dev"
    _chroot_mount -t devpts     -o rw,nosuid,noexec,gid=5,mode=620,ptmxmode=000 devpts      "$chroot_dir/dev/pts"
    _chroot_mount -t tmpfs      -o rw,nosuid,nodev                              tmpfs       "$chroot_dir/dev/shm"
    _chroot_mount -t tmpfs      -o rw,nosuid,nodev,mode=755                     tmpfs       "$chroot_dir/run"

    _mount_resolv_conf

    chroot_setup_times=1

    _chroot_debug "Done (setup)"
}

chroot_teardown() {
    local _mountpoints=()

    if [[ -z "$chroot_dir" ]] || (( ${#chroot_active_mounts[@]} == 0 )); then
        _chroot_debug "chroot_dir is not set, nothing to tear down"
        return
    fi

    if (( chroot_setup_times == 0 )); then
        _chroot_debug "Nothing to tear down in $chroot_dir"
        return
    elif (( chroot_setup_times > 1 )); then
        chroot_setup_times=$(( chroot_setup_times - 1 ))
        _chroot_debug "chroot_setup_times=$chroot_setup_times"
        return
    fi

    _chroot_debug "Tearing down chroot environment in \"$chroot_dir\""

    while (( ${#chroot_active_mounts[@]} > 0 )); do
        local _mp
        for _mp in "${chroot_active_mounts[@]}"; do
            if mountpoint -q "$_mp" >&2; then
                if ! umount "$_mp"; then
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
    chroot_setup_times=0

    _chroot_debug "Done (teardown)"
}

chroot_teardown_force() {
    chroot_setup_times=1
    chroot_teardown
}

chroot_run() {
    SHELL=/bin/bash PATH="$CHROOT_PATH" LC_ALL=C chroot "$@"
}

chroot_pid_unshare_run() {
    SHELL=/bin/bash PATH="$CHROOT_PATH" LC_ALL=C unshare --fork --pid chroot "$@"
}

debug "${BASH_SOURCE[0]} sourced"
