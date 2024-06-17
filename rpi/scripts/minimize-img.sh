#!/bin/bash

script_name="$(basename "$0")"
script_path="$(readlink -f "$0")"
script_dir="$(dirname "$script_path")"

source=""
fs_type=""
declare -i is_device=0

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
    if [[ "$_error" -gt 0 ]]; then
        exit "$_error"
    fi
}

usage() {
    local _usage="
    Usage: $script_name [ -h | --help ] -t|--target <target> [ -b|--base-onle | -u|--use-base <basee_image> ]

    -h, --help                              display this help message and exit
    -t, --source <image file or device>     specify the source image file or device to be minimalized
    -f, --fs-type <filesystem>              specify the image filesystem type (ext4)
"
    echo "$_usage"
}

find_source_file() {
    if [[ -f "$source" ]]; then
        is_device=0
        info "Image file is \"$source\""
        error "Image file is not supported yet." 1
    elif [[ -b "$source" ]]; then
        is_device=1
        info "Device is \"$source\""
    else
        error "Cannot find image file or device \"$source\"." 1
    fi
}

umount_device() {
    if [[ $is_device -eq 0 ]]; then
        return
    fi

    if mountpoint -q "$source"; then
        info "Unmounting device \"$source\"..."
        umount "$mountpoint"
    fi
}

minimalize_ext4() {
    info "Minimalizing EXT4 image..."

    e2fsck -f -y "$source" || :

    local resize2fs_output=$(resize2fs -M "$source")
    echo "$resize2fs_output"
    local new_size=$(echo "$resize2fs_output" | grep "The filesystem on $source is now" | awk '{print $7}')
    info "New size: $new_size"

    e2fsck -f -y "$source" || :

    info "Resize partition..."
    # parted -s "$source" resizepart 1 (($new_size + 7))
}

################################################################################

set -e
set -u
# set -x

while (($# > 0)); do
    case "$1" in
    -h|--help)
        usage
        exit 0
        ;;
    -s|--source)
        shift
        source="$(readlink -f "$1")"
        ;;
    -f|--fs-type)
        shift
        fs_type="$1"
        ;;
    *)
        usage
        error "Unknown option: $1" 1
        ;;
    esac
    shift
done

if [[ -z "$source" ]]; then
    usage
    error "Missing source image file or device." 3
fi

echo -e "\e[1;30m"
echo -e "****************************************************************"
echo -e "               Minimizeing Image File or Device              "
echo -e "****************************************************************"
echo -e "[$script_name]: Start time - $(date)"
echo -e "\e[0m"

start_time=$(date +%s)

find_source_file
umount_device
if [[ "$fs_type" == "ext4" ]]; then
    minimalize_ext4
else
    error "Unsupported filesystem type \"$fs_type\"." 2
fi

end_time=$(date +%s)
total_time=$((end_time - start_time))

echo -e "\e[1;30m"
echo -e "****************************************************************"
echo -e "                Execution time Information                "
echo -e "****************************************************************"
echo -e "[$script_name]: End time - $(date)"
echo -e "[$script_name]: Total time - $(date -d@$total_time -u +%H:%M:%S)"
echo -e "\e[0m"