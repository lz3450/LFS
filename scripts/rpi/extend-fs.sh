#!/bin/bash
#
# extend-fs.sh
#

script_name="$(basename "$0")"
script_path="$(readlink -f "$0")"
script_dir="$(dirname "$script_path")"
version="1.0"
device=""

# Show an INFO message
# $1: message string
info() {
    local _msg="$1"
    printf '\033[0;32m[%s] INFO: %s\033[0m\n' "$script_name" "$_msg"
}

# Show a WARNING message
# $1: message string
warning() {
    local _msg="$1"
    printf '\033[0;33m[%s] WARNING: %s\033[0m\n' "$script_name" "$_msg" >&2
}

# Show an ERROR message then exit with status
# $1: message string
# $2: exit code number (with 0 does not exit)
error() {
    local _msg="$1"
    local _error="$2"
    printf '\033[0;31m[%s] ERROR: %s\033[0m\n' "$script_name" "$_msg" >&2
    if [ "$_error" -gt 0 ]; then
        exit "$_error"
    fi
}

usage() {
    local _usage="
    Usage: $script_name <device>
"
    echo "$_usage"
}

find_device() {
    device="${device%[0-9]*}"
    if [[ -b "$device" ]]; then
        info "Device is \"$device\""
    else
        usage
        error "Cannot find device \"$device\"." 1
    fi
}

resize_partation() {
    info "Resizeing partation..."

    sudo parted -s "$device" \
        resizepart 2 100% \
        unit s \
        print
}

extend_fs() {
    info "Extending filesystem..."

    sudo fsck.ext4 -f "${device}2"
    sudo resize2fs "${device}2"
}

################################################################################

set -e
set -x

if (($# > 1)); then
    error "Too many arguments" 1
fi
device="$1"

echo -e "\e[1;30m"
echo -e "****************************************************************"
echo -e "               Create Raspberry Pi image                "
echo -e "****************************************************************"
echo -e "[$script_name]: Start time - $(date)"
echo -e "\e[0m"

start_time=$(date +%s)

find_device
resize_partation
extend_fs

end_time=$(date +%s)
total_time=$((end_time - start_time))

echo -e "\e[1;30m"
echo -e "****************************************************************"
echo -e "                Execution time Information                "
echo -e "****************************************************************"
echo -e "[$script_name]: End time - $(date)"
echo -e "[$script_name]: Total time - $(date -d@$total_time -u +%H:%M:%S)"
echo -e "\e[0m"
