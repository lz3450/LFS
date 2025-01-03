#!/usr/bin/bash
#
# lib/util.sh
#

################################################################################

# requires: log.sh

################################################################################

### functions
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root" 255
    fi
}

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

### error codes
# 255: Must be run as root