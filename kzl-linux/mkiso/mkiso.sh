#!/bin/bash
#
# mkiso.sh
#

set -e -u
# set -x

umask 0022

script_name="$(basename "${0}")"
script_path="$(readlink -f "${0}")"
script_dir="$(dirname "${script_path}")"

pkg_list=(
    arch-install-scripts
    base
    debootstrap
    dosfstools
    dpkg
    f2fs-tools
    gptfdisk
    linux
    linux-firmware
    mdadm
    mtools
    nano
    nvme-cli
    openssh
    pacman-contrib
    parted
    rsync
    screen
    smartmontools
    tmux
    usbutils
    vim
    wget
    wpa_supplicant
    zsh zsh-autosuggestions zsh-syntax-highlighting
)
work_dir="/tmp/isotmp"
pacstrap_dir="${work_dir}"/rootfs
isofs_dir="${work_dir}"/iso
install_dir="LiveOS"
iso_name="kzllinux"
iso_label="KZLLINUX_$(date +%Y%m%d)"
iso_publisher="KZL Linux <https://github.com/kongzelun/LFS>"
iso_application="KZL Linux Live/Rescue CD"
iso_version="$(date +%Y%m%d)"
out_dir="${script_dir}"
image_name="${iso_name}-${iso_version}.iso"
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

make_iso_image() {
    info "Creating ISO image..."
    xorriso \
        -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -joliet \
        -joliet-long \
        -rational-rock \
        -volid "${iso_label}" \
        -appid "${iso_application}" \
        -publisher "${iso_publisher}" \
        -preparer "prepared by kzl" \
        -partition_offset 16 \
        -append_partition 2 'C12A7328-F81F-11D2-BA4B-00A0C93EC93B' "${work_dir}"/efiboot.img \
        -appended_part_as_gpt \
        -output "${out_dir}/${image_name}" \
        "${isofs_dir}/" &> "${log_dir}"/xorriso.log
    info "Done!"
}

make_rootfs_squashfs() {
    local image_path="${isofs_dir}/${install_dir}/squashfs.img"

    # Create a squashfs image and place it in the ISO 9660 file system.
    install -dm0755 -- "${isofs_dir}/${install_dir}"
    info "Creating SquashFS image, this may take some time..."
    mksquashfs "${pacstrap_dir}" "${image_path}" -noappend -comp xz -b 1M -Xbcj x86 -Xdict-size 1M &> "${log_dir}"/mksquashfs.log
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

make_efibootimg() {
    info "Setting up systemd-boot for UEFI booting..."
    # Calculate the required FAT image size in bytes
    imgsize="$(du -bc \
        "${pacstrap_dir}/usr/lib/systemd/boot/efi/systemd-bootx64.efi" \
        "${script_dir}/efiboot/loader.conf" \
        "${script_dir}/efiboot/kzl-linux.conf" \
        "${pacstrap_dir}/boot/vmlinuz-linux" \
        "${pacstrap_dir}/boot/initramfs-linux.img" \
        2>/dev/null | awk 'END { print $1 }')"

    # Convert from bytes to KiB and round up to the next full MiB with an additional MiB for reserved sectors.
    imgsize="$(awk 'function ceil(x){return int(x)+(x>int(x))}
            function byte_to_kib(x){return x/1024}
            function mib_to_kib(x){return x*1024}
            END {print mib_to_kib(ceil((byte_to_kib($1)+1024)/1024))}' <<< "${imgsize}"
    )"
    rm -f -- "${work_dir}"/efiboot.img
    info "Creating FAT image of size: ${imgsize} KiB..."
    mkfs.fat -F 32 -C -n ISO_EFI "${work_dir}"/efiboot.img "${imgsize}" &> /dev/null

    # Create the default/fallback boot path in which a boot loaders will be placed later.
    mmd -i "${work_dir}"/efiboot.img ::/EFI ::/EFI/BOOT

    # Copy systemd-boot EFI binary to the default/fallback boot path
    mcopy -i "${work_dir}"/efiboot.img \
        "${pacstrap_dir}"/usr/lib/systemd/boot/efi/systemd-bootx64.efi ::/EFI/BOOT/BOOTx64.EFI

    # Copy systemd-boot configuration files
    mmd -i "${work_dir}"/efiboot.img ::/loader ::/loader/entries
    mcopy -i "${work_dir}"/efiboot.img "${script_dir}"/efiboot/loader.conf ::/loader/
    sed "s|%ARCHISO_LABEL%|${iso_label}|g" "${script_dir}"/efiboot/kzl-linux.conf | mcopy -i "${work_dir}"/efiboot.img - ::/loader/entries/kzl-linux.conf

    # Copy kernel and initramfs to FAT image
    info "Preparing kernel and initramfs for the FAT file system..."
    mcopy -i "${work_dir}/efiboot.img" \
        "${pacstrap_dir}"/boot/vmlinuz-linux \
        "${pacstrap_dir}"/boot/initramfs-linux.img \
        ::/

    info "Done!"
}

make_initramfs() {
    info "Create initramfs..."
    dracut \
        --nomdadmconf \
        --nolvmconf \
        --xz \
        --add 'livenet dmsquash-live convertfs pollcdrom qemu qemu-net' \
        --omit 'plymouth' \
        --no-hostonly \
        --no-early-microcode \
        --force \
        --verbose \
        "${pacstrap_dir}/boot/initramfs-linux.img" &> "${log_dir}"/dracut.log
    info "Done!"
}

make_rootfs() {
    install -dm0755 -o 0 -g 0 -- "${pacstrap_dir}"
    install -dm0755 -- "${isofs_dir}/${install_dir}"
    install -dm0755 -- "${log_dir}"

    # Write build date to file
    printf '%s\n' "$(date +%s)" > "${isofs_dir}/build_date"

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
    info "Copying custom repository..."
    cp -af --no-preserve=ownership,mode -- /home/.repository "${pacstrap_dir}"/home/.repository
    info "Done!"

    info "Creating a list of installed packages on live-enviroment..."
    pacman -Q --sysroot "${pacstrap_dir}" > "${isofs_dir}"/pkglist.txt
    info "Done!"
}

build() {
    # Set up essential directory paths
    pacstrap_dir="${work_dir}"/rootfs
    isofs_dir="${work_dir}"/iso

    # Create working directory
    if [[ ! -d "${work_dir}" ]]; then
        install -d -- "${work_dir}"
    fi

    make_rootfs
    make_initramfs
    make_efibootimg
    cleanup_pacstrap_dir
    make_rootfs_squashfs
    make_iso_image
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
