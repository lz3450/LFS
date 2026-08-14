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
    local _mountpoint="${@: -1}"

    if ! mount -v "$@" >&2; then
        _chroot_error "Failed to mount \"$_mountpoint\""
        return 1
    fi

    chroot_active_mounts=("$_mountpoint" "${chroot_active_mounts[@]}")
}

_resolve_symlink_with_root() {
    local _target=$1
    local _root=${2%/}

    _target=$(readlink -m "$_target")

    if [[ -n "$_root" && "$_target" != "$_root"* ]]; then
        _target="$_root/${_target#/}"
    fi

    echo "$_target"
}

_mount_resolv_conf() {
    local _src=$(_resolve_symlink_with_root "/etc/resolv.conf" "")
    local _dst=$(_resolve_symlink_with_root "$chroot_dir/etc/resolv.conf" "$chroot_dir")

    if [[ ! -e "$_src" ]]; then
        _chroot_warn "Host /etc/resolv.conf does not exist"
        return 0
    fi

    if [[ ! -e "$_dst" ]]; then
        if [[ "$_dst" = "$chroot_dir/etc/resolv.conf" ]]; then
            # There may be no resolv.conf in the chroot. In this case, we'll just exit.
            # The chroot environment must not be concerned with DNS resolution.
            _chroot_warn "/etc/resolv.conf does not exist in the chroot environment"
            _chroot_warn "Skipping mounting of host /etc/resolv.conf"
            return 0
        fi

        install -Dm644 /dev/null "$_dst" || return 1
    fi

    _chroot_info "Mounting host /etc/resolv.conf onto \"$_dst\""
    _chroot_mount --bind -o X-mount.nocanonicalize=target "$_src" "$_dst"
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

    if [[ ! -d "$_chroot_dir" ]]; then
        _chroot_error "\"$_chroot_dir\" is not a directory"
        return 1
    fi

    if ! mountpoint -q "$_chroot_dir"; then
        _chroot_error "\"$_chroot_dir\" is not a mountpoint"
        _chroot_error "Please run \`mount --bind $_chroot_dir $_chroot_dir\`"
        return 1
    fi

    chroot_dir="$_chroot_dir"

    _chroot_debug "Setting up chroot environment in \"$chroot_dir\""

    if ! _chroot_mount -t proc      -o rw,nosuid,nodev,noexec                       proc        "$chroot_dir/proc" ||
       ! _chroot_mount -t sysfs     -o ro,nosuid,nodev,noexec                       sysfs       "$chroot_dir/sys" ||
       ! _chroot_mount -t devtmpfs  -o rw                                           devtmpfs    "$chroot_dir/dev" ||
       ! _chroot_mount -t devpts    -o rw,nosuid,noexec,gid=5,mode=620,ptmxmode=000 devpts      "$chroot_dir/dev/pts" ||
       ! _chroot_mount -t tmpfs     -o rw,nosuid,nodev                              tmpfs       "$chroot_dir/dev/shm" ||
       ! _chroot_mount -t tmpfs     -o rw,nosuid,nodev,mode=755                     tmpfs       "$chroot_dir/run" ||
       ! _mount_resolv_conf; then
        _chroot_error "Failed to set up chroot environment in \"$chroot_dir\""
        chroot_teardown
        return 1
    fi

    _chroot_debug "Done (setup)"
}

# chroot_setup_with_efi <chroot_dir>
# Set up a chroot and mount efivarfs inside it.
chroot_setup_with_efi() {
    local _chroot_dir="$1"

    chroot_setup "$_chroot_dir" || return 1

    if ! _chroot_mount -t efivarfs  -o rw,nosuid,nodev,noexec efivarfs "$chroot_dir/sys/firmware/efi/efivars"; then
        _chroot_error "Failed to set up efivarfs in chroot environment \"$chroot_dir\""
        chroot_teardown
        return 1
    fi
}

chroot_teardown() {
    local _mountpoints=()

    if [[ -z "$chroot_dir" ]]; then
        _chroot_debug "\"chroot_dir\" is not set, nothing to tear down"
        return
    fi

    if (( ${#chroot_active_mounts[@]} == 0 )); then
        _chroot_debug "No active chroot mounts to tear down"
        chroot_dir=""
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

    chroot_dir=""
    _chroot_debug "Done (teardown)"
}

chroot_run() {
    SHELL=/bin/bash PATH="$CHROOT_PATH" LC_ALL=C chroot "$@"
}

chroot_pid_unshare_run() {
    SHELL=/bin/bash PATH="$CHROOT_PATH" LC_ALL=C unshare --fork --pid chroot "$@"
}

debug "${BASH_SOURCE[0]} sourced"
