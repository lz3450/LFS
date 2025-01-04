#!/usr/bin/bash
#
# lib/loop.sh
#

################################################################################

if [[ -n "${__LOOP__:-}" ]]; then
    return
fi

declare -i __LOOP__=1

################################################################################

### libraries
source "$(dirname ${BASH_SOURCE[0]})"/log.sh

### checks
check_root

### functions
setup_loop() {
    local _img="$1"

    info "Setup loop device for image \"$_img\"..."

    local _loop=$(losetup -f)
    info "Loop device is \"$_loop\""
    losetup -P "$_loop" "$_img"
    echo "$_loop"

    info "Done"
}


debug "${BASH_SOURCE[0]} sourced"
