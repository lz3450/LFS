#!/bin/bash
#
# install.rpi.sh
#

################################################################################

if [[ -v __INSTALL_RPI__ ]]; then
    return
fi

declare -r __INSTALL_RPI__="install.rpi.sh"

################################################################################

### constants and variables
declare -ar COMMON_DEB_PKGS=(
    # build-essential
    initramfs-tools
    python3
    zstd
)
declare -ar DEBIAN_DEB_PKGS=(
    systemd-resolved
    systemd-timesyncd
    bluez
    ### firmware
    firmware-brcm80211
    firmware-realtek
    bluez-firmware
    ### raspi
    raspberrypi-archive-keyring
    raspberrypi-sys-mods
    raspberrypi-net-mods
    raspi-config
    raspi-firmware
    raspi-gpio
    raspi-utils
    rpi-eeprom
    # rpicam-apps-lite
)
declare -ar JAMMY_DEB_PKGS=(
    linux-firmware-raspi2
    ubuntu-raspi-settings
)
declare -ar NOBLE_DEB_PKGS=(
    linux-firmware-raspi
    linux-image-6.8.0-1065-raspi
    systemd-resolved
    systemd-timesyncd
)

deb_pkgs=("${COMMON_DEB_PKGS[@]}")

################################################################################

case "$arg_suite" in
    trixie)
        deb_pkgs+=("${DEBIAN_DEB_PKGS[@]}")
        ;;
    jammy)
        deb_pkgs+=("${JAMMY_DEB_PKGS[@]}")
        ;;
    noble)
        deb_pkgs+=("${NOBLE_DEB_PKGS[@]}")
        ;;
    *)
        error "Unsupported suite: $arg_suite" 128
        ;;
esac
readonly -a deb_pkgs

################################################################################

loop_device=""

### libraries
LIBDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1; pwd -P)"
. "$LIBDIR/chroot.sh"

### functions
prepare() {
    info "Preparing root filesystem on $loop_device..."

    # mkpart
    info "Setting up loop device for installation for RPi..."
    fallocate -l 2048MiB "$IMG_FILE"
    parted -s "$IMG_FILE" \
        mklabel msdos \
        unit s \
        mkpart primary fat32 1 1048575 \
        mkpart primary ext4 1048576 100% \
        print

    loop_device="$(loop_get_device)"
    readonly loop_device
    loop_partitioned_setup "$loop_device" "$IMG_FILE"

    # mkfs
    mkfs.fat -F 32 -n BOOT "${loop_device}p1"
    mkfs.ext4 -F -L ROOT "${loop_device}p2"

    # mount
    mount -v -o "$MOUNT_OPT" "${loop_device}p2" "$ROOTFS_DIR"
    mkdir -p "$ROOTFS_DIR/boot/firmware"
    mount -v -o "$MOUNT_OPT" "${loop_device}p1" "$ROOTFS_DIR/boot/firmware"
}

post_bootstrap_rootfs() {
    wget -qO "$CONFIG_DIR/rpi/cmdline.txt" https://raw.githubusercontent.com/RPi-Distro/pi-gen/refs/heads/master/stage1/00-boot-files/files/cmdline.txt
    wget -qO "$CONFIG_DIR/rpi/config.txt" https://raw.githubusercontent.com/RPi-Distro/pi-gen/refs/heads/master/stage1/00-boot-files/files/config.txt

    if [[ "$distro" == "debian" ]]; then
        info "Setting up raspberrypi sources.list..."
        mkdir -p "$ROOTFS_DIR/etc/apt/sources.list.d"
        cat > "$ROOTFS_DIR/etc/apt/sources.list.d/raspi.sources" << EOF
Types: deb
URIs: https://archive.raspberrypi.com/debian/
Suites: $arg_suite
Components: main
Signed-By: /etc/apt/trusted.gpg.d/raspberrypi.gpg.key
#Signed-By: /etc/apt/trusted.gpg.d/raspberrypi-archive-stable.gpg
EOF
        # raspberrypi-archive-stable.gpg will be overwritten by deb package raspberrypi-archive-keyring
        wget -qO "$ROOTFS_DIR/etc/apt/trusted.gpg.d/raspberrypi.gpg.key" https://archive.raspberrypi.org/debian/raspberrypi.gpg.key
    fi
}

post_install_pkgs() {
    if [[ "$distro" == "debian" ]]; then
        # raspberrypi-archive-stable.gpg will be overwritten by deb package raspberrypi-archive-keyring
        info "Setting up sources.list..."
        rm -vf "$ROOTFS_DIR/etc/apt/trusted.gpg.d/raspberrypi.gpg.key"
        sed -i -e '/^Signed-By/d' -e '/^#Signed-By/s/^#//' "$ROOTFS_DIR/etc/apt/sources.list.d/raspi.sources"
    fi
}

configure_rootfs_platform_specific() {
    ###
    cat > "$ROOTFS_DIR"/etc/issue << EOF
Ubuntu for Raspberry Pi \n (\s \m \r) \t \l

EOF
    mkdir -p "$ROOTFS_DIR"/etc/issue.d
    cat > "$ROOTFS_DIR"/etc/issue.d/00-ip.issue << EOF

IPv4 address: \4
IPv6 address: \6

EOF

    ###
    info "Downloading RPi firmware..."
    local _firmware_version=$(git ls-remote --tags https://github.com/raspberrypi/firmware.git | grep -oP '(?<=refs/tags/)1.\d{8}$' | sort -V | tail -n1)
    local _firmware_dir="$WORK_DIR/firmware-$_firmware_version"
    wget -qO "$WORK_DIR/firmware.tar.gz" https://github.com/raspberrypi/firmware/archive/refs/tags/$_firmware_version.tar.gz
    tar -xf "$WORK_DIR/firmware.tar.gz" -C "$WORK_DIR"

    ###
    info "Copying firmware in raspberrypi/firmware to rootfs..."
    cp -rf "$_firmware_dir"/boot/*.bin "$ROOTFS_DIR/boot/firmware/"
    cp -rf "$_firmware_dir"/boot/*.dat "$ROOTFS_DIR/boot/firmware/"
    cp -rf "$_firmware_dir"/boot/*.elf "$ROOTFS_DIR/boot/firmware/"
    info "Copying kernel images in raspberrypi/firmware to rootfs..."
    if [[ "$distro" == "debian" ]]; then
        cp -rf "$_firmware_dir"/modules "$ROOTFS_DIR/usr/lib/"
        local _kernel_version
        local _kv
        local _kernel_suffix
        local -a _kernel_version_suffix=()
        for _kernel_version in $(ls "$ROOTFS_DIR/usr/lib/modules"); do
            _kv=$(echo "$_kernel_version" | grep -oP '\d+\.\d+\.\d+\K.*' | sed 's/^-v//;s/\+//')
            case "$_kv" in
                8-16k)  _kernel_suffix="_2712" ;;
                8-rt)  _kernel_suffix="8_rt" ;;
                *)      _kernel_suffix="$_kv" ;;
            esac
            cp -vdr "$ROOTFS_DIR/boot/firmware/kernel$_kernel_suffix.img" "$ROOTFS_DIR/boot/vmlinuz-$_kernel_version"
            chroot_run "$ROOTFS_DIR" update-initramfs -k "$_kernel_version" -c
            cp -vdr "$ROOTFS_DIR/boot/initrd.img-$_kernel_version" "$ROOTFS_DIR/boot/firmware/initramfs$_kernel_suffix"
            _kernel_version_suffix+=("$_kernel_version:$_kernel_suffix")
        done
    elif [[ "$distro" == "ubuntu" ]]; then
    install -Dm755 /dev/stdin "$ROOTFS_DIR"/boot/update-kernel.sh << EOF
#!/usr/bin/bash
#
# update-kernel.sh
#

if [[ \$EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

kernel_version=\$(realpath /boot/vmlinuz | xargs basename | sed 's/^vmlinuz-//')

update-initramfs -k "\$kernel_version" -c

cp -v /boot/vmlinuz /boot/firmware/kernel8.img
cp -v /boot/initrd.img /boot/firmware/initramfs8
cp /usr/lib/firmware/"\$kernel_version"/device-tree/broadcom/* /boot/firmware/
cp -r /usr/lib/firmware/"\$kernel_version"/device-tree/overlays /boot/firmware/
EOF
    chroot_run "$ROOTFS_DIR" /boot/update-kernel.sh
    fi

    ###
    info "Initializing rootfs..."
    chroot_run "$ROOTFS_DIR" /usr/bin/bash -e -u -o pipefail -s >> "$LOG_DIR/${FUNCNAME[0]}.log" << EOF
useradd -m -U -G adm,dialout,sudo,audio,video -s /bin/zsh kzl
echo "root:raspi" | chpasswd
echo "kzl:raspi" | chpasswd

systemctl disable wpa_supplicant.service
# systemctl disable NetworkManager.service
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service
systemctl enable wpa_supplicant@wlan0.service
systemctl enable ssh.service
EOF

    ###
    info "Copying miscellaneous config files..."
    # environment
    cp -vf "$CONFIG_DIR/rpi/profile" "$ROOTFS_DIR/etc/profile"
    # passwd
    sed -i '/^root/s|/bin/bash|/bin/zsh|' "$ROOTFS_DIR"/etc/passwd
    # network
    ln -sf wpa_supplicant.conf "$ROOTFS_DIR/etc/wpa_supplicant/wpa_supplicant-wlan0.conf"
    # rfkill
    if [[ "$distro" == "debian" ]]; then
        sed -i 's/^options[[:space:]]\+rfkill[[:space:]]\+default_state=0$/options rfkill default_state=1/' \
            "$ROOTFS_DIR/etc/modprobe.d/rfkill_default.conf"
    fi

    ###
    info "Copying boot configuration files..."
    # copy configuration files
    cp -vf "$CONFIG_DIR/rpi/cmdline.txt" "$ROOTFS_DIR/boot/firmware/cmdline.txt"
    cp -vf "$CONFIG_DIR/rpi/config.txt" "$ROOTFS_DIR/boot/firmware/config.txt"
    # get PARTUUIDs of the partitions
    local b_partuuid=$(findmnt -n -o PARTUUID --source "${loop_device}p1")
    local r_partuuid=$(findmnt -n -o PARTUUID --source "${loop_device}p2")
    if [[ -z "$b_partuuid" ]]; then
        error "Cannot find PARTUUID of BOOT partition!" 4
    fi
    info "BOOT PARTUUID: $b_partuuid"
    if [[ -z "$r_partuuid" ]]; then
        error "Cannot find PARTUUID of ROOT partition!" 4
    fi
    info "ROOT PARTUUID: $r_partuuid"
    # set PARTUUIDs in fstab and cmdline.txt
    cat > "$ROOTFS_DIR/etc/fstab" << EOF
PARTUUID=$r_partuuid        /                   ext4        defaults                0 1
PARTUUID=$b_partuuid        /boot/firmware      vfat        defaults,noatime        0 2
#/swapfile                   none                swap        defaults                0 0
EOF
    sed -i "s/ROOTDEV/PARTUUID=$r_partuuid/" "$ROOTFS_DIR/boot/firmware/cmdline.txt"
    if [[ "$distro" == "ubuntu" ]]; then
        sed -i -E 's| init=.*||' "$ROOTFS_DIR/boot/firmware/cmdline.txt"
        sed -i "s/ resize//" "$ROOTFS_DIR/boot/firmware/cmdline.txt"
    fi
}

cleanup_platform_specific() {
    ###
    debug "Cleaning up root filesystem..."
    umount -v "$ROOTFS_DIR/boot/firmware"
    delete_all_contents "$ROOTFS_DIR/boot/firmware/"
    clean_rootfs "$ROOTFS_DIR" >> "$LOG_DIR/${FUNCNAME[0]}.log"

    ###
    loop_unmount "$loop_device"
    loop_detach "$loop_device"
}

finalize() {
    ###
    cp -v "$IMG_FILE" "$SCRIPT_DIR/images/$IMG_FILE_NAME"
    chown ${SUDO_UID:-0}:${SUDO_GID:-0} "$SCRIPT_DIR/images/$IMG_FILE_NAME"
    log_cyan "Successfully installed ${distro^} ${arg_suite^} Raspberry Pi on $SCRIPT_DIR/images/$IMG_FILE_NAME"
}

debug "${BASH_SOURCE[0]} sourced"
