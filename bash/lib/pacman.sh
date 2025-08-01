#!/bin/bash
#
# pacman.sh
#

################################################################################

if [[ -v __PACMAN__ ]]; then
    return
fi

declare -r __PACMAN__="pacman.sh"

################################################################################

### libraries
LIBDIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1; pwd -P)"
. "$LIBDIR/log.sh"
. "$LIBDIR/utils.sh"
if [[ -f "/etc/makepkg.conf" ]]; then
    . /etc/makepkg.conf
elif [[ -f "/opt/etc/makepkg.conf" ]]; then
    . /opt/etc/makepkg.conf
else
    error "makepkg.conf NOT found" 4
fi

### constants & variables
if [[ -f "/usr/bin/pacman" ]]; then
    declare -r PACMAN="/usr/bin/pacman"
    declare -r PACMAN_CONFIG="/etc/pacman.conf"
elif [[ -f "/opt/bin/pacman" ]]; then
    declare -r PACMAN="/opt/bin/pacman"
    declare -r PACMAN_CONFIG="/opt/etc/pacman.conf"
else
    error "Failed to find \`pacman\`" 127
fi

declare -r EXTENSION="tar.zst"
#                 epoch:                         pkgver-pkgrel-                    arch.pkg.tar.zst
declare -r PKGNAME_REGEX="\([0-9]+:\)?\([0-9a-zA-Z]+\(\.\|\+\)?\)+-[0-9]+-\(x86_64\|aarch64\|any\).pkg.$EXTENSION"

### functions
_pacman_debug() {
    debug "${1:-}" "${BASH_SOURCE[0]##*/}"
}
_pacman_info () {
    info "${1:-}" "${BASH_SOURCE[0]##*/}"
}
_pacman_error() {
    error "${1:-}" "${2:-}" "${BASH_SOURCE[0]##*/}"
}

pacman_get_pkg_file() {
    local _pkg="$1"
    local _dir="$2"
    #               pkgname-
    local _pkg_regex="$_pkg-$PKGNAME_REGEX"
    if [[ -d "$_dir" ]]; then
        find "$_dir" -type f -regex "$_dir/$_pkg_regex" -printf "%T@ %f\n" | LC_ALL=C sort -n | tail -n 1 | cut -d ' ' -f 2
    fi
}

# pacman_get_pkgbase <pkgname>
# $1: pkgname
pacman_get_pkgbase() {
    local _pkgbase
    case "$1" in
        device-mapper) _pkgbase=lvm2 ;;
        linux-headers) _pkgbase=linux ;;
        *) _pkgbase="$1" ;;
    esac
    echo "$_pkgbase"
}

# pacman_get_pkgnames <pkgbase>
# $1: pkgbase
pacman_get_pkgnames() {
    local -a _pkgnames
    case "$1" in
        linux) _pkgnames=("linux" "linux-headers") ;;
        lvm2) _pkgnames=("lvm2" "device-mapper") ;;
        *) _pkgnames=("$1") ;;
    esac
    echo "${_pkgnames[@]}"
}

pacman_bootstrap() {
    local _rootfs_dir="$1"
    local -n _pacman_pkgs="$2"

    _pacman_debug "Installing pacman packages: $(IFS=','; echo "${_pacman_pkgs[*]}")"
    mkdir -v -m 0755 -p "$_rootfs_dir"/var/{cache/pacman/pkg,lib/pacman,log} "$_rootfs_dir"/{dev,run,etc/pacman.d}
    mkdir -v -m 1777 -p "$_rootfs_dir"/tmp
    mkdir -v -m 0555 -p "$_rootfs_dir"/{sys,proc}

    local _pacman_tmp_conf_file=$(mktemp -p /tmp pacman.XXX.conf)
    sed 's/^DownloadUser/#&/' "$PACMAN_CONFIG" > "$_pacman_tmp_conf_file"

    pacman -Syy
    unshare --fork --pid \
        "$PACMAN" -Sy \
        -r "$_rootfs_dir" \
        --config "$_pacman_tmp_conf_file" \
        --disable-sandbox \
        --noconfirm \
        "${_pacman_pkgs[@]}"
    _pacman_debug "Done"
}

pacman_get_installed_pkgs() {
    local _rootfs_dir="$1"
    "$PACMAN" -Q --sysroot "$_rootfs_dir"
}

debug "${BASH_SOURCE[0]} sourced"
