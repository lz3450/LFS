#!/bin/bash
#
# loop.sh
#

################################################################################

if [[ -v __LIBLOOP__ ]]; then
    return
fi

declare -r __LIBLOOP__="loop.sh"

################################################################################

### libraries
LIBDIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1; pwd -P)"
. "$LIBDIR"/log.sh

### functions
# Get first unused loop device
# loop_get_device
# echo: loop device name
loop_get_device() {
    echo "$(losetup -f)"
}

# Setup loop device
# loop_setup <loop_device> <image_file>
# $1: loop device name
# $2: image file name
loop_partitioned_setup() {
    local _loop_device="$1"
    local _img="$2"
    info "Setting up loop device for image: $_img"
    losetup -P "$_loop_device" "$_img" || error "Failed to setup loop device: $_loop_device" 1
    info "Done (Setting up loop device)"
}

# detach loop device
# loop_teardown <loop_device>
# $1: loop device name
loop_teardown() {
    local _loop_device="${1:-}"
    if [[ -z "$_loop_device" ]]; then
        return
    fi

    local _loop_mountpoints=()
    local _mountpoints=()
    readarray -t _loop_mountpoints < <(mount | grep "$_loop_device" | cut -d ' ' -f 3 | tac)

    while (( ${#_loop_mountpoints[@]} > 0 )); do
        local _mp
        for _mp in "${_loop_mountpoints[@]}"; do
            info "Unmounting \"$_mp\"..."
            if umount -v -- "$_mp"; then
                info "Unmounted \"$_mp\"."
            else
                _mountpoints+=("$_mp")
                warn "Failed to unmount \"$_mp\", retry later"
            fi
        done
        _loop_mountpoints=("${_mountpoints[@]}")
        _mountpoints=()
    done

    info "Detaching loop device: $_loop_device"
    losetup -d "$_loop_device" || error "Failed to detach loop device: $_loop_device" 2
    info "Done (Detaching loop device)"
}

debug "${BASH_SOURCE[0]} sourced"

### error codes
# 1: setup
# 2: teardown
