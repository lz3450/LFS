#!/bin/bash
#
# libtemplate.sh
#

################################################################################

if [[ -v __LIBMKROOTFS__ ]]; then
    return
fi

declare -r __LIBMKROOTFS__="libtemplate.sh"

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
. log.sh
. utils.sh
# . chroot.sh
# . loop.sh

### functions
