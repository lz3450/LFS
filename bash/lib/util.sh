#!/usr/bin/bash
#
# lib/chroot.sh
#

################################################################################

### functions
delete_dir() {
    local _dir="$1"
    if [[ -d "$_dir" ]]; then
        find "$_dir" -delete
    fi
}
delete_all() {
    local _dir="$1"
    if [[ -d "$_dir" ]]; then
        find "$_dir" -mindepth 1 -delete
    fi
}
delete_direct_files() {
    local _dir="$1"
    if [[ -d "$_dir" ]]; then
        find "$_dir" -maxdepth 1 -type f -delete
    fi
}
delete_all_files() {
    local _dir="$1"
    if [[ -d "$_dir" ]]; then
        find "$_dir" -type f -delete
    fi
}

dir_empty() {
    local _dir="$1"
    if [[ -d "$_dir" ]]; then
       [[ -z $(ls -A "$_dir") ]]
    else
        return 0
    fi
}
