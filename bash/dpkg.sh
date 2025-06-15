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
. log.sh

### functions
dpkg_clean_rootfs() {
    rm -vrf "$ROOTFS_DIR"/dev/*
    rm -vrf "$ROOTFS_DIR"/run/*
    rm -vrf "$ROOTFS_DIR"/tmp/*
    rm -vrf "$ROOTFS_DIR"/usr/share/doc/*
    rm -vrf "$ROOTFS_DIR"/var/cache/apt/archives/*.deb
    rm -vrf "$ROOTFS_DIR"/var/cache/ldconfig/*
    rm -vrf "$ROOTFS_DIR"/var/lib/apt/lists/*
    rm -vrf "$ROOTFS_DIR"/var/log/*
    rm -vrf "$ROOTFS_DIR"/var/tmp/*
}
