#!/bin/bash
#
# dpkg.sh
#

################################################################################

if [[ -v __LIBDPKG__ ]]; then
    return
fi

declare -r __LIBDPKG__="dpkg.sh"

################################################################################

### libraries
LIBDIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1; pwd -P)"
. "$LIBDIR/log.sh"

### functions
dpkg_clean_rootfs() {
    local _rootfs_dir="$1"
    if [[ ! -d "$_rootfs_dir" ]]; then
        error "Root filesystem directory is not specified" 1
    fi
    rm -vrf "$_rootfs_dir"/dev/*
    rm -vrf "$_rootfs_dir"/run/*
    rm -vrf "$_rootfs_dir"/tmp/*
    rm -vrf "$_rootfs_dir"/usr/share/doc/*
    rm -vrf "$_rootfs_dir"/var/cache/apt/archives/*.deb
    rm -vrf "$_rootfs_dir"/var/cache/ldconfig/*
    rm -vrf "$_rootfs_dir"/var/lib/apt/lists/*
    rm -vrf "$_rootfs_dir"/var/log/*
    rm -vrf "$_rootfs_dir"/var/tmp/*
}

### error codes
# 1: general error
