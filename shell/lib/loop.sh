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
_loop_info () {
    info "${1:-}" "${BASH_SOURCE[0]##*/}"
}
_loop_warn() {
    warn "${1:-}" "${BASH_SOURCE[0]##*/}"
}
_loop_error() {
    error "${1:-}" "${2:-}" "${BASH_SOURCE[0]##*/}"
}

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
    _loop_info "Setting up loop device for image: $_img"
    losetup -P "$_loop_device" "$_img" || _loop_error "Failed to setup loop device: $_loop_device" 1
    _loop_info "Done (Setting up loop device)"
}

# detach loop device
# loop_teardown <loop_device>
# $1: loop device name
loop_teardown() {
    local _loop_device="${1:-}"
    if [[ -z "$_loop_device" ]]; then
        return
    fi

    sync

    local _loop_mountpoints=()
    local _mountpoints=()
    readarray -t _loop_mountpoints < <(mount | grep "$_loop_device" | cut -d ' ' -f 3 | tac)

    while (( ${#_loop_mountpoints[@]} > 0 )); do
        local _mp
        for _mp in "${_loop_mountpoints[@]}"; do
            if ! umount -v -- "$_mp"; then
                _mountpoints+=("$_mp")
                _loop_warn "Failed to unmount \"$_mp\", retry later"
            fi
        done
        _loop_mountpoints=("${_mountpoints[@]}")
        _mountpoints=()
        sleep 3
    done

    _loop_info "Detaching loop device: $_loop_device"
    losetup -d "$_loop_device" || _loop_error "Failed to detach loop device: $_loop_device" 2
    _loop_info "Done (Detaching loop device)"
}

debug "${BASH_SOURCE[0]} sourced"

### error codes
# 1: setup
# 2: teardown
