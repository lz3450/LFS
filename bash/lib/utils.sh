#!/bin/bash
#
# utils.sh
#

################################################################################

if [[ -v __UTILS___ ]]; then
    return
fi

declare -r __UTILS___="utils.sh"

################################################################################

### libraries
LIBDIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1; pwd -P)"
. "$LIBDIR"/log.sh

### functions
_utils_debug() {
    debug "${1:-}" "${BASH_SOURCE[0]##*/}"
}
_utils_info () {
    info "${1:-}" "${BASH_SOURCE[0]##*/}"
}
_utils_warn() {
    warn "${1:-}" "${BASH_SOURCE[0]##*/}"
}
_utils_error() {
    error "${1:-}" "${2:-}" "${BASH_SOURCE[0]##*/}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        _utils_error "This script must be run as root" 255
    fi
}

# Delete recursively all files and directories under $1, including $1 itself
delete_all() {
    local _dir="$1"
    if [[ -d "$_dir" ]]; then
        find "$_dir" -print -delete
    fi
}
# Delete all contents inside $1, but not $1 itself
delete_all_contents() {
    local _dir="$1"
    if [[ -d "$_dir" ]]; then
        find "$_dir" -mindepth 1 -print -delete
    fi
}
# Delete only regular files directly inside $1, and not subdirectories or their contents
delete_direct_files() {
    local _dir="$1"
    if [[ -d "$_dir" ]]; then
        find "$_dir" -maxdepth 1 -type f -print -delete
    fi
}
# Delete recursively all regular files under $1, including those in subdirectories
delete_all_files() {
    local _dir="$1"
    if [[ -d "$_dir" ]]; then
        find "$_dir" -type f -print -delete
    fi
}

# Check if a directory is empty (no files or subdirectories)
dir_empty() {
    local _dir="$1"
    [[ -d "$_dir" ]] && [[ -z "$(find "$_dir" -mindepth 1 -print -quit)" ]]
}

clean_rootfs() {
    local _rootfs_dir="$1"
    if [[ ! -d "$_rootfs_dir" ]]; then
        _utils_error "Root filesystem directory is not a directory" 1
    fi

    _utils_debug "Cleaning rootfs..."
    # general
    if mountpoint -q "$_rootfs_dir/dev"; then
        _utils_warn "$_rootfs_dir/dev is a mountpoint, skipping /dev cleanup"
        ls -lA "$_rootfs_dir/dev/"
    else
        delete_all_contents "$_rootfs_dir/dev/"
    fi
    if mountpoint -q "$_rootfs_dir/run"; then
        _utils_warn "$_rootfs_dir/run is a mountpoint, skipping /run cleanup"
        ls -lA "$_rootfs_dir/run/"
    else
        delete_all_contents "$_rootfs_dir/run/"
    fi
    delete_all_contents "$_rootfs_dir"/tmp/
    delete_all_contents "$_rootfs_dir"/usr/share/doc/
    delete_all_contents "$_rootfs_dir"/var/cache/
    delete_all_contents "$_rootfs_dir"/var/log/
    delete_all_contents "$_rootfs_dir"/var/tmp/
    # apt
    delete_all_contents "$_rootfs_dir"/var/lib/apt/lists/
    # pacman
    delete_all_contents "$_rootfs_dir"/var/lib/pacman/
    find "$_rootfs_dir" -type f \( -name '*.pacnew' -o -name '*.pacsave' \) -delete
    _utils_debug "Done"
}

debug "${BASH_SOURCE[0]} sourced"

### error codes
# 255: Must be run as root
