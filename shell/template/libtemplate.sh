#!/bin/bash
#
# libtemplate.sh
#

################################################################################

if [[ -v __LIBTEMPLATE__ ]]; then
    return
fi

declare -r __LIBTEMPLATE__="libtemplate.sh"

################################################################################

### checks
check_root

## optional variables
if [[ -z "$optional" ]]; then
    info "optional unbound, using empty list"
    optional="default"
fi

## required variables
if [[ -z "$required" ]]; then
    error "required unbound" 2
fi

### libraries
LIBDIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1; pwd -P)"
. "$LIBDIR"/log.sh
. "$LIBDIR"/utils.sh
# . "$LIBDIR"/chroot.sh
# . "$LIBDIR"/loop.sh
# . "$LIBDIR"/pacman.sh
# . "$LIBDIR"/deb.sh

### functions
_info () {
    info "${1:-}" "${BASH_SOURCE[0]##*/}"
}
_warn() {
    warn "${1:-}" "${BASH_SOURCE[0]##*/}"
}
_error() {
    error "${1:-}" "${2:-}" "${BASH_SOURCE[0]##*/}"
}

debug "${BASH_SOURCE[0]} sourced"
