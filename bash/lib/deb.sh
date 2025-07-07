#!/bin/bash
#
# libdeb.sh
#

################################################################################

if [[ -v __LIBDEB__ ]]; then
    return
fi

declare -r __LIBDEB__="libdeb.sh"

################################################################################

### libraries
LIBDIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1; pwd -P)"
. "$LIBDIR"/log.sh
. "$LIBDIR"/utils.sh
. "$LIBDIR"/chroot.sh

### functions
_deb_debug() {
    debug "${1:-}" "${BASH_SOURCE[0]##*/}"
}
_deb_info () {
    info "${1:-}" "${BASH_SOURCE[0]##*/}"
}

# $1: rootfs_dir: the rootfs directory
# $2: deb_pkgs: an array of Debian packages to install
deb_apt_install() {
    local _rootfs_dir="$1"
    local -n _deb_pkgs="$2"

    _deb_debug "Installing deb packages: $(IFS=','; echo "${_deb_pkgs[*]}")"
    chroot_setup "$_rootfs_dir"
    chroot_run "$_rootfs_dir" /bin/bash -e -u -o pipefail -s << EOF
apt-get update
apt-get upgrade -y
apt-get install --no-install-recommends -y ${_deb_pkgs[@]}
apt-get autoremove --purge -y
EOF
    chroot_teardown
    _deb_debug "Done"
}

# $1: rootfs_dir: the rootfs directory
deb_set_locale() {
    local _rootfs_dir="$1"

    chroot_setup "$_rootfs_dir"
    chroot_run "$_rootfs_dir" /bin/bash -e -u -o pipefail -s << EOF
dpkg-reconfigure locales
dpkg-reconfigure tzdata
EOF
    chroot_teardown
    _deb_debug "Set locale"
}

deb_get_installed_pkgs() {
    local _rootfs_dir="$1"
    chroot_run "$_rootfs_dir" dpkg-query -W -f='${Package}\n'
}

debug "${BASH_SOURCE[0]} sourced"
