#!/bin/bash
#
# mkimg.sh
#

set -e -u
# set -x

script_name="$(basename "${0}")"
script_path="$(readlink -f "${0}")"
script_dir="$(dirname "${script_path}")"
img="/tmp/raspi.img"
mountpoint="/tmp/raspi"
loop=""
chroot_path="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"
base_img=""

# Show an INFO message
# $1: message string
info() {
    local _msg="${1}"
    printf '[%s] INFO: %s\n' "${script_name}" "${_msg}"
}

# Show a WARNING message
# $1: message string
warning() {
    local _msg="${1}"
    printf '[%s] WARNING: %s\n' "${script_name}" "${_msg}" >&2
}

# Show an ERROR message then exit with status
# $1: message string
# $2: exit code number (with 0 does not exit)
error() {
    local _msg="${1}"
    local _error="${2}"
    printf '[%s] ERROR: %s\n' "${script_name}" "${_msg}" >&2
    if [ "${_error}" -gt 0 ]; then
        exit "${_error}"
    fi
}

usage() {
    local _usage="
    Usage: ${script_name} [ -h | --help ] -u|--use-base <basee_image>

    -h, --help                      display this help message and exit
    -u, --use-base <base_image>     use existing base image
"
    echo "${_usage}"
}

setup_loop() {
    info "Setup loop device..."

    loop=$(losetup -f)
    info "Loop device is \"${loop}\""

    losetup -P "${loop}" "${img}"
}

mount_img() {
    info "Mounting image..."

    mkdir -p "${mountpoint}"
    mount "${loop}p2" "${mountpoint}"
    # if [ "${target}" == "debian" ]; then
    #     mkdir -p "${mountpoint}"/boot
    #     mount ${loop}p1 "${mountpoint}"/boot
    # elif [ "${target}" == "ubuntu" ]; then
    #     mkdir -p "${mountpoint}"/boot/firmware
    #     mount ${loop}p1 "${mountpoint}"/boot/firmware
    # fi
    mkdir -p "${mountpoint}"/boot
    mount "${loop}p1" "${mountpoint}"/boot

}

configure_img() {
    info "Configuring image..."

    for fs in dev sys proc run; do
        mount --rbind /"${fs}" "${mountpoint}"/"${fs}"
        mount --make-rslave "${mountpoint}"/"${fs}"
    done

    LC_ALL=C PATH="${chroot_path}" chroot "${mountpoint}" /bin/bash
    LC_ALL=C PATH="${chroot_path}" chroot "${mountpoint}" sync

    rm "${mountpoint}"/root/initialize.sh

    for fs in dev sys proc run; do
        umount -R "${mountpoint}"/$fs
    done

    rm -rf var/lib/apt/lists/*
    rm -rf dev/*
    rm -rf var/log/*
    rm -rf var/cache/apt/archives/*.deb
    rm -rf var/tmp/*
    rm -rf tmp/*

    sync
}

cleanup() {
    info "Cleaning..."
    set +e

    if [ -n "${mountpoint}" ]; then
        for attempt in $(seq 10); do
            for fs in dev/pts dev sys proc run; do
                mount | grep -q "${mountpoint}/${fs}" && umount -R "${mountpoint}/${fs}" 2> /dev/null
            done
            mount | grep -q "${mountpoint}" && umount -R "${mountpoint}" 2> /dev/null
            if [ $? -ne 0 ]; then
                break
            fi
            sleep 1
        done
    fi

    losetup -D
    if [ -d "${mountpoint}" ]; then
        rmdir "${mountpoint}"
    fi

    if [ -f "${img}" ]; then
        rm -f "${img}"
    fi
}
trap cleanup EXIT

################################################################################

while [ $# -gt 0 ]; do
    case "${1}" in
    -h|--help)
        usage
        exit 0
        ;;
    -u|--use-base)
        shift
        base_img="$(readlink -f "${1}")"
        ;;
    *)
        usage
        error "Unknown option: ${1}" 1
        ;;
    esac
    shift
done

if [ -d "${mountpoint}" ]; then
    error "${mountpoint} exists, please remove before restart!" 3
fi

cp "${base_img}" "${img}"
setup_loop
mount_img
configure_img

end_time=$(date +%s)
total_time=$((end_time-start_time))
