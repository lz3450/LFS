#!/bin/bash
#
# chroot.sh
#

################################################################################

if [[ -v __LIBCHROOT__ ]]; then
    return
fi

declare -r __LIBCHROOT__="chroot.sh"

################################################################################

### libraries
LIBDIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1; pwd -P)"
. "$LIBDIR"/log.sh

### constants & variables
CHROOT_PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:/opt/bin:/opt/sbin"

chroot_active_mounts=()
chroot_dir=""
declare -i chroot_setup_done=0

### functions
_chroot_info () {
    info "${1:-}" "${BASH_SOURCE[0]##*/}"
}
_chroot_warn() {
    warn "${1:-}" "${BASH_SOURCE[0]##*/}"
}

chroot_add_mount() {
    mount -v "$@" >&2
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
    local _src=$(_resolve_link "/etc/resolv.conf")
    local _dest=$(_resolve_link "$chroot_dir/etc/resolv.conf" "$chroot_dir")

    # If we don't have a source resolv.conf file, there's nothing useful we can do.
    if [[ ! -e $_src ]]; then
        return
    fi

    if [[ ! -e $_dest ]]; then
        # There are two reasons the destination might not exist:
        #
        #   1. There may be no resolv.conf in the chroot.  In this case, $_dest won't exist,
        #      and it will be equal to $1/etc/resolv.conf.  In this case, we'll just exit.
        #      The chroot environment must not be concerned with DNS resolution.
        #
        #   2. $1/etc/resolv.conf is (or resolves to) a broken link.  The environment
        #      clearly intends to handle DNS resolution, but something's wrong.  Maybe it
        #      normally creates the target at boot time.  We'll (try to) take care of it by
        #      creating a dummy file at the target, so that we have something to bind to.

        # Case 1.
        if [[ "$_dest" = "$chroot_dir/etc/resolv.conf" ]]; then
            return
        fi

        # Case 2.
        install -D -m 644 /dev/null "$_dest"
    fi

    chroot_add_mount --bind "$_src" "$_dest"
}

# chroot_setup <chroot_dir>
# $1: the directory to chroot into
# when using `chroot_setup`, `chroot_teardown` must be call to clean up
# for example, `trap chroot_teardown EXIT`
chroot_setup() {
    if (( chroot_setup_done > 0 )); then
        _chroot_info "chroot_setup has already been called. Skipping"
        return
    fi

    chroot_active_mounts=()
    chroot_dir="$1"

    _chroot_info "Setting up chroot environment in \"$chroot_dir\""

    if ! mountpoint -q "$chroot_dir"; then
        _chroot_info "\"$chroot_dir\" is not a mountpoint. This may have undesirable side effects. Bind mounting \"$chroot_dir\" to itself"
        chroot_add_mount --bind --make-private "$chroot_dir" "$chroot_dir"
    fi

    chroot_add_mount -t sysfs -o ro,nosuid,nodev,noexec sys "$chroot_dir/sys"
    chroot_add_mount -t proc -o nosuid,nodev,noexec proc "$chroot_dir/proc"
    chroot_add_mount -t devtmpfs -o nosuid,mode=755 udev "$chroot_dir/dev"
    chroot_add_mount -t devpts -o nosuid,noexec,gid=5,mode=620,ptmxmode=000 devpts "$chroot_dir/dev/pts"
    chroot_add_mount -t tmpfs -o nosuid,nodev,noexec,mode=755 run "$chroot_dir/run"
    chroot_add_mount -t tmpfs -o nosuid,nodev shm "$chroot_dir/dev/shm"
    chroot_add_mount -t tmpfs -o nosuid,nodev,mode=1777 tmp "$chroot_dir/tmp"
    if [[ -d "$chroot_dir/sys/firmware/efi/efivars" ]]; then
        chroot_add_mount -t efivarfs -o nosuid,nodev,noexec efivarfs "$chroot_dir/sys/firmware/efi/efivars"
    fi

    _add_resolv_conf

    chroot_setup_done=1

    _chroot_info "Done (Setup chroot environment)"
}

chroot_teardown() {
    local _mountpoints=()

    if (( chroot_setup_done == 0 )); then
        return
    fi

    _chroot_info "Tearing down chroot environment in \"$chroot_dir\""

    while (( ${#chroot_active_mounts[@]} > 0 )); do
        local _mp
        for _mp in "${chroot_active_mounts[@]}"; do
            if mountpoint -q "$_mp"; then
                if ! umount -v -- "$_mp"; then
                    _mountpoints+=("$_mp")
                    _chroot_warn "Failed to unmount \"$_mp\", retry later"
                fi
            else
                _chroot_info "Mountpoint \"$_mp\" is not mounted, skipping"
            fi
        done
        chroot_active_mounts=("${_mountpoints[@]}")
        _mountpoints=()
        sleep 3
    done
    chroot_setup_done=0

    _chroot_info "Done (Tear down chroot environment)"
}

chroot_run() {
    # SHELL=/bin/bash LC_ALL=C PATH="$CHROOT_PATH" unshare --fork --pid chroot "$@"
    SHELL=/bin/bash PATH="$CHROOT_PATH" LC_ALL=C unshare --fork --pid chroot "$@"
}

debug "${BASH_SOURCE[0]} sourced"
