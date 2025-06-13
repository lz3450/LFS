#!/bin/bash
#
# loop.sh
#

################################################################################

if [[ -v __LOOP__ ]]; then
    return
fi

declare -r __LOOP__="loop.sh"

################################################################################

### libraries
LIBDIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1; pwd -P)"
. "$LIBDIR"/log.sh
. "$LIBDIR"/utils.sh

### checks
check_root

### functions
# Get first unused loop device
# loop_get_unused
# echo: loop device name
loop_get_unused() {
    local _loop=$(losetup -f)
    echo "$_loop"
}

# Setup loop device
# loop_setup <loop_device> <image_file>
# $1: loop device name
# $2: image file name
loop_setup() {
    local _loop_device="$1"
    local _img="$2"
    info "Setting up loop device for image: $_img"
    losetup -P "$_loop_device" "$_img"
    info "Done (Setting up loop device)"
}

# detach loop device
# loop_teardown <loop_device>
# $1: loop device name
loop_teardown() {
    local _loop_device="$1"
    if [[ -z "$_loop_device" ]]; then
        return 0
    fi
    info "Detaching loop device: $_loop_device"
    losetup -d "$_loop_device"
    info "Done (Detaching loop device)"
}

debug "${BASH_SOURCE[0]} sourced"
