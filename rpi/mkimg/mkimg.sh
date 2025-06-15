#!/bin/bash
#
# mkimg.sh
#

script_name="$(basename "$0")"
script_path="$(readlink -f "$0")"
script_dir="$(dirname "$script_path")"
img="/tmp/raspi.img"
mountpoint="/tmp/raspi"
loop=""
chroot_path="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"
target=""
fs_type=""
declare -i base_only=0
base_img=""

common_deb_pkgs=(
    initramfs-tools
    sudo
    nano
    wpasupplicant iw
    wget curl
    openssh-server
    git
    bash-completion
    zsh
    zsh-syntax-highlighting
    zsh-autosuggestions
    build-essential
)
debian_deb_pkgs=(
    systemd-resolved
    systemd-timesyncd
)
ubuntu_deb_pkgs=(
    linux-firmware-raspi
    # ubuntu-raspi-settings
)

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

    -h, --help                      display this help message and exit
    -t, --target <distro>           specify the image distribution (debian, ubuntu)
    -f, --fs-type <filesystem>      specify the image filesystem type (ext4, f2fs)
    -b, --base-onle                 only create base image
    -u, --use-base <base_image>     use existing base image
"
    echo "$_usage"
}

create_img_file() {
    info "Creating image..."

    if [[ -f "$img" ]]; then
        rm -f "$img"
    fi

    fallocate -l 1536MiB "$img"

    parted -s "$img" \
        mktable msdos \
        unit s \
        mkpart primary fat32 1s 524287s \
        mkpart primary "$fs_type" 524288s 100% \
        print
}

setup_loop() {
    info "Setup loop device..."

    loop=$(losetup -f)
    info "Loop device is \"$loop\""

    losetup -P "$loop" "$img"
}

format_img() {
    info "Formating image..."

    mkfs.fat -F32 "${loop}p1"
    mkfs."$fs_type" "${loop}p2"
}

mount_img() {
    info "Mounting image..."

    mkdir -p "$mountpoint"
    mount "${loop}p2" "$mountpoint"
    mkdir -p "$mountpoint"/boot/firmware
    mount "${loop}p1" "$mountpoint"/boot/firmware
}

bootstrap_img () {
    info "Bootstrap image..."

    local -a _pkg_list
    local _suite
    local _mirror

    # debootstrap
    if [[ "$target" == "debian" ]]; then
        _pkg_list=("${common_deb_pkgs[@]}" "${debian_deb_pkgs[@]}")
        _suite="bookworm"
        _mirror="http://deb.debian.org/debian"
    elif [[ "$target" == "ubuntu" ]]; then
        _pkg_list=("${common_deb_pkgs[@]}" "${ubuntu_deb_pkgs[@]}")
        _suite="jammy"
        _mirror="http://ports.ubuntu.com"
    else
        error "Unsupported target distribution \"$target\"." 1
    fi

    debootstrap \
        --arch=arm64 \
        --foreign \
        --include="$(IFS=','; echo "${_pkg_list[*]}")" \
        --components=main,restricted,universe \
        --merged-usr \
        "$_suite" \
        "$mountpoint" \
        "$_mirror"

    LC_ALL=C PATH="$chroot_path" chroot "$mountpoint" /debootstrap/debootstrap --second-stage

    sync
}

configure_img() {
    info "Copying sources.list..."
    cp -f "sources-$target.list" "$mountpoint"/etc/apt/sources.list
    if [[ "$target" == "debian" ]]; then
        cp -f raspi.list "$mountpoint"/etc/apt/sources.list.d/
        wget -qO - http://archive.raspberrypi.org/debian/raspberrypi.gpg.key | gpg --dearmor | tee "$mountpoint"/etc/apt/trusted.gpg.d/raspberrypi >/dev/null
    fi

    info "Copying RPi firmware..."
    cp -dr firmware/boot/* "$mountpoint"/boot/firmware/
    cp -dr firmware/modules "$mountpoint"/usr/lib/
    for kernel_version in $(ls firmware/modules); do
        kv=$(echo "$kernel_version" | sed -e 's#.*[0-9]\.[0-9]\.[0-9]\+\(-v\)\?\(.*\)+#\2#')
        case "$kv" in
            8-16k)
                kv="_2712"
                ;;
        esac
        cp -dr firmware/boot/kernel$kv.img "$mountpoint"/boot/vmlinuz-$kernel_version
        kernel_version_kvs+=("$kernel_version:$kv")
    done

    info "Mounting system filesystems..."
    for fs in dev sys proc run; do
        mount --rbind /"$fs" "$mountpoint/$fs"
        mount --make-rslave "$mountpoint/$fs"
    done

    info "Running initialize.sh..."
    cp "initialize-$target.sh" "$mountpoint"/initialize.sh
    LC_ALL=C PATH="$chroot_path" chroot "$mountpoint" /bin/bash -c "/initialize.sh"
    rm "$mountpoint"/initialize.sh

    info "Unmounting system filesystems..."
    for fs in dev sys proc run; do
        umount -R "$mountpoint"/$fs
    done

    info "Copying initramfs..."
    for kernel_version_kv in "${kernel_version_kvs[@]}"; do
        kernel_version=${kernel_version_kv%%:*}
        kv=${kernel_version_kv##*:}
        cp -dr "$mountpoint/boot/initrd.img-$kernel_version" "$mountpoint/boot/firmware/initramfs$kv"
    done

    info "Clean mountpoint..."
    rm -rf "$mountpoint"/var/lib/apt/lists/*
    rm -rf "$mountpoint"/dev/*
    rm -rf "$mountpoint"/var/log/*
    rm -rf "$mountpoint"/var/cache/apt/archives/*.deb
    rm -rf "$mountpoint"/var/tmp/*
    rm -rf "$mountpoint"/tmp/*

    info "Copying configuration files..."
    cp -f "config.txt" "$mountpoint"/boot/firmware/config.txt
    cp -f "cmdline-$target.txt" "$mountpoint"/boot/firmware/cmdline.txt
    cp -f fstab "$mountpoint"/etc/fstab

    info "Setting PARTUUID..."
    bootpartuuid=$(blkid -s PARTUUID | grep ${loop}p1 | sed -e 's#.*=\"\(.*\)\"#\1#')
    test -z "$bootpartuuid" && error "cannot find boot partuuid!" 1
    info "BOOT PARTUUID: $bootpartuuid"
    rootpartuuid=$(blkid -s PARTUUID | grep ${loop}p2 | sed -e 's#.*=\"\(.*\)\"#\1#')
    test -z "$rootpartuuid" && error "cannot find root partuuid!" 1
    info "ROOT PARTUUID: $rootpartuuid"
    sed -i "s|%BOOTPARTUUID%|$bootpartuuid|" "$mountpoint"/etc/fstab
    sed -i "s|%ROOTPARTUUID%|$rootpartuuid|" "$mountpoint"/etc/fstab
    sed -i "s|%ROOTPARTUUID%|$rootpartuuid|" "$mountpoint"/boot/firmware/cmdline.txt
    sed -i "s|%FS_TYPE%|$fs_type|" "$mountpoint"/etc/fstab
    sed -i "s|%FS_TYPE%|$fs_type|" "$mountpoint"/boot/firmware/cmdline.txt

    sync
}

cleanup() {
    info "Cleaning..."
    set +e

    if [[ -n "$mountpoint" ]]; then
        for attempt in {1..10}; do
            for fs in dev/pts dev sys proc run; do
                mount | grep -q "$mountpoint/$fs" && umount -R "$mountpoint/$fs" 2> /dev/null
            done
            mount | grep -q "$mountpoint" && umount -R "$mountpoint" 2> /dev/null
            if [[ $? -ne 0 ]]; then
                break
            fi
            sleep 1
        done
    fi

    if [[ -n "$loop" ]]; then
        losetup -d "$loop"
    fi
    if [[ -d "$mountpoint" ]]; then
        rmdir "$mountpoint"
    fi
}
trap cleanup EXIT

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
    -t|--target)
        shift
        target="$1"
        ;;
    -f|--fs-type)
        shift
        fs_type="$1"
        ;;
    -b|--base-only)
        base_only=1
        ;;
    -u|--use-base)
        shift
        base_img="$(readlink -f "$1")"
        ;;
    *)
        usage
        error "Unknown option: $1" 1
        ;;
    esac
    shift
done

if [[ "$target" != "debian" ]] && [[ "$target" != "ubuntu" ]]; then
    usage
    error "Unsupported target distribution \"$target\"." 1
fi

if [[ ! -f "$base_img" ]] && [[ "$fs_type" != "f2fs" ]] && [[ "$fs_type" != "ext4" ]]; then
    usage
    error "Unsupported filesystem type \"$fs_type\"." 2
fi

if [[ -d "$mountpoint" ]]; then
    error "$mountpoint exists, please remove before restart!" 3
fi

# base-only and use-base are mutually exclusive
if [[ -f "$base_img" ]] && [[ $base_only -ne 0 ]]; then
    info "Nothing to do."
    exit 0
fi


echo -e "\e[1;30m"
echo -e "****************************************************************"
echo -e "               Create Raspberry Pi image                "
echo -e "****************************************************************"
echo -e "[$script_name]: Start time - $(date)"
echo -e "\e[0m"
start_time=$(date +%s)

if [[ -f "$base_img" ]]; then
    cp "$base_img" "$img"
    setup_loop
    mount_img
    fs_type=$(blkid -s TYPE | grep ${loop}p2 | sed -e 's#.*=\"\(.*\)\"#\1#')
else
    create_img_file
    setup_loop
    format_img
    mount_img
    bootstrap_img
    info "Copy base image..."
    cp -v "$img" "$script_dir/${target}-${fs_type}-raspi-base-$(date +%Y%m%d_%H%M%S).img"
    chown $SUDO_UID:$SUDO_GID "$script_dir/${target}-${fs_type}-raspi-base-$(date +%Y%m%d_%H%M%S).img"
fi

if [[ $base_only -eq 0 ]]; then
    configure_img
    info "Copy full image..."
    cp -v "$img" "$script_dir/${target}-${fs_type}-raspi-$(date +%Y%m%d_%H%M%S).img"
    chown $SUDO_UID:$SUDO_GID "$script_dir/${target}-${fs_type}-raspi-$(date +%Y%m%d_%H%M%S).img"
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
