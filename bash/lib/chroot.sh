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
CHROOT_PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:/opt/bin:/opt/sbin"

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

chroot_add_mount() {
    mount "$@" >&2
    chroot_active_mounts=(${@: -1} "${chroot_active_mounts[@]}")
}

_resolve_link() {
    local _target="$1"
    local _rootfs="${2:-}"

    while [[ -L "$_target" ]]; do
        _target=$(readlink -m "$_target")
        # If a root was given, make sure the target is under it.
        # Make sure to strip any leading slash from target first.
        if [[ -n "$_rootfs" && "$_target" != "$_rootfs"* ]]; then
            _target="${_rootfs%/}/${_target#/}"
        fi
    done

    echo "$_target"
}

_add_resolv_conf() {
    local _source=$(_resolve_link "/etc/resolv.conf")
    local _target=$(_resolve_link "$chroot_dir/etc/resolv.conf" "$chroot_dir")

    # If we don't have a source resolv.conf file, there's nothing useful we can do.
    if [[ ! -e $_source ]]; then
        return
    fi

    if [[ ! -e $_target ]]; then
        # There are two reasons the destination might not exist:
        #
        #   1. There may be no resolv.conf in the chroot.  In this case, $_target won't exist,
        #      and it will be equal to $1/etc/resolv.conf.  In this case, we'll just exit.
        #      The chroot environment must not be concerned with DNS resolution.
        #
        #   2. $1/etc/resolv.conf is (or resolves to) a broken link.  The environment
        #      clearly intends to handle DNS resolution, but something's wrong.  Maybe it
        #      normally creates the target at boot time.  We'll (try to) take care of it by
        #      creating a dummy file at the target, so that we have something to bind to.

        # Case 1.
        if [[ "$_target" = "$chroot_dir/etc/resolv.conf" ]]; then
            return
        fi

        # Case 2.
        install -D -m 644 /dev/null "$_target"
    fi

    chroot_add_mount --bind "$_source" "$_target"
}

# chroot_setup <chroot_dir>
# $1: the directory to chroot into
# when using `chroot_setup`, `chroot_teardown` must be call to clean up
# for example, `trap chroot_teardown EXIT`
chroot_setup() {
    if (( chroot_setup_times > 0 )); then
        chroot_setup_times=$(( chroot_setup_times + 1 ))
        _chroot_debug "chroot_setup_times=$chroot_setup_times"
        return
    fi

    chroot_dir="$1"

    _chroot_debug "Setting up chroot environment in \"$chroot_dir\""

    if ! mountpoint -q "$chroot_dir"; then
        # if chroot_dir is not a mountpoint, there may be undesirable side effects.
        # bind mounting chroot_dir to itself
        chroot_add_mount --rbind "$chroot_dir" "$chroot_dir"
    fi
    mount --make-private "$chroot_dir"

    chroot_add_mount -t sysfs       -o ro,nosuid,nodev,noexec                       sysfs       "$chroot_dir/sys"
    chroot_add_mount -t proc        -o rw,nosuid,nodev,noexec                       proc        "$chroot_dir/proc"
    chroot_add_mount -t devtmpfs    -o rw,inode64                                   devtmpfs    "$chroot_dir/dev"
    chroot_add_mount -t devpts      -o rw,nosuid,noexec,gid=5,mode=620,ptmxmode=000 devpts      "$chroot_dir/dev/pts"
    chroot_add_mount -t tmpfs       -o rw,nosuid,nodev,mode=755,inode64             tmpfs       "$chroot_dir/run"
    chroot_add_mount -t tmpfs       -o rw,nosuid,nodev,inode64                      tmpfs       "$chroot_dir/dev/shm"
    chroot_add_mount -t tmpfs       -o rw,nosuid,nodev,inode64                      tmpfs       "$chroot_dir/tmp"
    chroot_add_mount -t efivarfs    -o rw,nosuid,nodev,noexec                       efivarfs    "$chroot_dir/sys/firmware/efi/efivars"

    _add_resolv_conf

    chroot_setup_times=1

    _chroot_debug "Done"
}

chroot_teardown() {
    local _mountpoints=()

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
                if ! umount -R -- "$_mp"; then
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

    _chroot_debug "Done"
}

chroot_teardown_force() {
    chroot_setup_times=1
    chroot_teardown
}

chroot_run() {
    SHELL=/bin/bash PATH="$CHROOT_PATH" LC_ALL=C unshare --fork --pid chroot "$@"
}

debug "${BASH_SOURCE[0]} sourced"
