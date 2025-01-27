#!/usr/bin/bash
#
# lib/pacman.sh
#

################################################################################

if [[ -n "${__PACMAN__:-}" ]]; then
    return
fi

declare -i __PACMAN__=1

################################################################################

### constants & variables
EXTENSION="tar.zst"
#                 epoch:                         pkgver-pkgrel-                    arch.pkg.tar.zst
PKGNAME_REGEX="\([0-9]+:\)?\([0-9a-zA-Z]+\(\.\|\+\)?\)+-[0-9]+-\(x86_64\|aarch64\|any\).pkg.$EXTENSION"

### functions
get_pkg_file() {
    local _pkg="$1"
    local _dir="$2"
    #               pkgname-
    local _pkg_regex="$_pkg-$PKGNAME_REGEX"
    if [[ -d "$_dir" ]]; then
        find "$_dir" -type f -regex "$_dir/$_pkg_regex" -printf "%T@ %f\n" | LC_ALL=C sort -n | tail -n 1 | cut -d ' ' -f 2
    fi
}

get_pkgbase() {
    local _pkgbase
    case "$1" in
        device-mapper)
            _pkgbase=lvm2
            ;;
        *)
            _pkgbase="$1"
            ;;
    esac
    echo "$_pkgbase"
}

get_pkgnames() {
    local -a _pkgnames
    case "$1" in
        linux)
            _pkgnames=("linux" "linux-headers")
            ;;
        *)
            _pkgnames=("$1")
            ;;
    esac
    echo "${_pkgnames[@]}"
}

debug "${BASH_SOURCE[0]} sourced"
