#!/bin/bash
#
# mkrootfs.sh
#

set -e -u
# set -x

umask 0022

script_name="$(basename "${0}")"
script_path="$(readlink -f "${0}")"
script_dir="$(dirname "${script_path}")"

pkg_list=(
    base
    dpkg
    nano
    openssh
    pacman-contrib
    parted
    rsync
    tmux
    usbutils
    vim
    wget
    zsh zsh-autosuggestions zsh-syntax-highlighting
)
work_dir="/tmp/rootfstmp"
pacstrap_dir="${work_dir}"/rootfs
rootfs_archive_name="rootfs.tar.gz"
out_dir="${script_dir}"
log_dir="${work_dir}"/log

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
    local _error=${2}
    printf '[%s] ERROR: %s\n' "${script_name}" "${_msg}" >&2
    if (( _error > 0 )); then
        exit "${_error}"
    fi
}

usage() {
    cat <<USAGETEXT

Usage: ${script_name} [options]
    Options:
        -h              display this help message and exit
USAGETEXT
    exit ${1}
}

make_rootfs_archive() {
    info "Creating rootfs archive..."
    tar -czvf "${rootfs_archive_name}" \
        -C "${pacstrap_dir}" \
        . \
        &> "${log_dir}"/tar.log
    info "Done!"
}

# Cleanup rootfs
cleanup_pacstrap_dir() {
    info "Cleaning up in pacstrap location..."

    # Delete all files in /boot
    if [[ -d "${pacstrap_dir}/boot" ]]; then
        find "${pacstrap_dir}/boot" -mindepth 1 -delete
    fi
    # Delete pacman database sync cache files (*.tar.gz)
    if [[ -d "${pacstrap_dir}/var/lib/pacman" ]]; then
        find "${pacstrap_dir}/var/lib/pacman" -maxdepth 1 -type f -delete
    fi
    # Delete pacman database sync cache
    if [[ -d "${pacstrap_dir}/var/lib/pacman/sync" ]]; then
        find "${pacstrap_dir}/var/lib/pacman/sync" -delete
    fi
    # Delete pacman package cache
    if [[ -d "${pacstrap_dir}/var/cache/pacman/pkg" ]]; then
        find "${pacstrap_dir}/var/cache/pacman/pkg" -type f -delete
    fi
    # Delete all log files, keeps empty dirs.
    if [[ -d "${pacstrap_dir}/var/log" ]]; then
        find "${pacstrap_dir}/var/log" -type f -delete
    fi
    # Delete all temporary files and dirs
    if [[ -d "${pacstrap_dir}/var/tmp" ]]; then
        find "${pacstrap_dir}/var/tmp" -mindepth 1 -delete
    fi
    # Delete package pacman related files.
    find "${work_dir}" \( -name '*.pacnew' -o -name '*.pacsave' -o -name '*.pacorig' \) -delete
    # Create an empty /etc/machine-id
    rm -f -- "${pacstrap_dir}/etc/machine-id"
    printf '' > "${pacstrap_dir}/etc/machine-id"

    info "Done!"
}

make_rootfs() {
    install -dm0755 -o 0 -g 0 -- "${pacstrap_dir}"
    install -dm0755 -- "${log_dir}"

    # Copy custom root file system files.
    if [[ -d "${script_dir}/rootfs" ]]; then
        info "Update rootfs..."
        ./update_rootfs.sh &> "${log_dir}"/update_rootfs.log
        info "Done!"
        info "Copying custom airootfs files..."
        cp -af --no-preserve=ownership,mode -- "${script_dir}"/rootfs/. "${pacstrap_dir}"
        # Set ownership and mode for files and directories
        chown -fh -- 0:0 "${pacstrap_dir}"/etc/shadow
        chmod -f -- 400 "${pacstrap_dir}"/etc/shadow
        chown -fh -- 0:0 "${pacstrap_dir}"/root
        chmod -f -- 750 "${pacstrap_dir}"/root
        info "Done!"
    fi

    info "Installing packages to '${pacstrap_dir}/'..."
    env -u TMPDIR pacstrap -c -G -M -- "${pacstrap_dir}" "${pkg_list[@]}" &> "${log_dir}"/pacstrap.log
    info "Done!"

    # Copy custom repository
    # info "Copying custom repository..."
    # cp -af --no-preserve=ownership,mode -- /home/.repository "${pacstrap_dir}"/home/.repository
    # info "Done!"

    info "Creating a list of installed packages on live-enviroment..."
    pacman -Q --sysroot "${pacstrap_dir}" > "${pacstrap_dir}"/pkglist.txt
    info "Done!"
}

build() {
    # Create working directory
    if [[ -d "${work_dir}" ]]; then
        info "Remove existing work directory..."
        rm -rf "${work_dir}"
    fi
    install -d -- "${work_dir}"

    make_rootfs
    cleanup_pacstrap_dir
    make_rootfs_archive
}

cleanup() {
    info "Cleaning..."
    info "Done!"
}
trap cleanup ERR

################################################################

while getopts 'h?' arg; do
    case "${arg}" in
        h) usage 0 ;;
        ?) usage 1 ;;
    esac
done

start_time=$(date +%s)

echo "****************************************************************"
echo "                mkiso                "
echo "****************************************************************"

build

end_time=$(date +%s)
total_time=$((end_time-start_time))

echo "****************************************************************"
echo "                Execution time Information                "
echo "****************************************************************"
echo "${script_name} : End time - $(date)"
echo "${script_name} : Total time - $(date -d@${total_time} -u +%H:%M:%S)"
