#!/bin/bash
#
# install.sh
#

set -e

mountpoint="/mnt"
debootstrap_suite="noble"
common_deb_pkgs=(
    sudo
    nano
    parted fdisk
    dosfstools
    e2fsprogs
    xfsprogs
    bcachefs-tools
    f2fs-tools
    wpasupplicant
    wget curl
    openssh-server
    git
    bash-completion
    zsh
    linux-image-generic
    initramfs-tools
    zstd
    build-essential
    ### pacman
    libarchive-tools
    libgpgme-dev
)
noble_deb_pkgs=(
    systemd-boot
    systemd-resolved
)
declare -a deb_pkgs


if (($# != 1)); then
    echo "Usage: $0 <suite>"
    exit 1
fi

case "$1" in
    noble)      debootstrap_suite="noble" ;;
    jammy)      debootstrap_suite="jammy" ;;
    *)          echo "Unknown suite \"$1\"" && exit 1
esac

# debootstrap
if [[ "$debootstrap_suite" == "jammy" ]]; then
    deb_pkgs=("${common_deb_pkgs[@]}")
elif [[ "$debootstrap_suite" == "noble" ]]; then
    deb_pkgs=("${common_deb_pkgs[@]}" "${noble_deb_pkgs[@]}")
fi
debootstrap \
    --arch="amd64" \
    --include="$(IFS=','; echo "${deb_pkgs[*]}")" \
    --components=main,restricted,universe \
    --merged-usr \
    "$debootstrap_suite" \
    "$mountpoint" \
    http://us.archive.ubuntu.com/ubuntu

if [[ "$debootstrap_suite" == "noble" ]]; then
    rmdir -v "$mountpoint"/bin.usr-is-merged
    rmdir -v "$mountpoint"/sbin.usr-is-merged
    rmdir -v "$mountpoint"/lib.usr-is-merged
fi

# sources.list
tee "$mountpoint"/etc/apt/sources.list << EOF
deb http://us.archive.ubuntu.com/ubuntu $debootstrap_suite main restricted universe
deb-src http://us.archive.ubuntu.com/ubuntu $debootstrap_suite main restricted universe

deb http://us.archive.ubuntu.com/ubuntu/ $debootstrap_suite-updates main restricted universe
deb-src http://us.archive.ubuntu.com/ubuntu/ $debootstrap_suite-updates main restricted universe

deb http://security.ubuntu.com/ubuntu/ $debootstrap_suite-security main restricted universe
deb-src http://security.ubuntu.com/ubuntu/ $debootstrap_suite-security main restricted universe
EOF

# pacman
if [[ -f "/usr/local/bin/pacman" ]]; then
    mkdir -m 0755 -p -- "$mountpoint"/var/{cache/pacman/pkg,lib/pacman}
    mkdir -p -- "$mountpoint"/home/.repository/kzl
    pacman -Sy -r "$mountpoint" --noconfirm --cachedir "$mountpoint"/home/.repository/kzl pacman linux
fi

# swap
fallocate -l 16G "$mountpoint"/swapfile
chmod 600 "$mountpoint"/swapfile
mkswap "$mountpoint"/swapfile

# hostname
read -p 'hostname: ' HOSTNAME
echo $HOSTNAME > "$mountpoint"/etc/hostname

# network
tee "$mountpoint"/etc/systemd/network/wlan.network << EOF
[Match]
Name=wl*

[Network]
DHCP=yes
EOF
tee "$mountpoint"/etc/systemd/network/ethernet.network << EOF
[Match]
Name=en*
Name=eth*

[Network]
DHCP=yes
EOF
tee "$mountpoint"/etc/wpa_supplicant/wpa_supplicant-wlan.conf << EOF
network={
	ssid="LuckySKZLJ"
	psk=51d8558a663cf1d191b42cd88d542e3847ce4da204196fa016c30728bc67f6e3
}
network={
	ssid="S3Lab"
	psk=9dfacd4f5b26c7bfde13a184acb4b202eba5b2870cb2d6dccd10ac53012d0706
}
EOF

# if [[ -f "$mountpoint"/etc/NetworkManager/NetworkManager.conf ]]; then
#     mv "$mountpoint"/etc/NetworkManager/NetworkManager.conf "$mountpoint"/etc/NetworkManager/NetworkManager.conf.backup
# fi
# cat > "$mountpoint"/etc/NetworkManager/NetworkManager.conf << EOF
# [main]
# plugins=keyfile,ifupdown

# [keyfile]
# unmanaged-devices=none

# [ifupdown]
# managed=true
# EOF

# grml-zsh-config
wget -O "$mountpoint"/root/.zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc
echo 'source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> "$mountpoint"/root/.zshrc
echo 'source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh' >> "$mountpoint"/root/.zshrc

cp initialize.sh "$mountpoint"/root

# Assume that LFS located at "/home/LFS"
BASH_LIB_DIR="/home/LFS/bash/lib" ./kzl-chroot "$mountpoint" /bin/bash

# boot
mkdir -p "$mountpoint"/boot/efi/loader/entries
tee "$mountpoint"/boot/efi/loader/loader.conf << EOF
timeout 3
console-mode max
default ubuntu.conf
EOF
tee "$mountpoint"/boot/efi/loader/entries/ubuntu.conf << EOF
title   Ubuntu
linux   /vmlinuz
initrd  /initrd.img
options root=PARTUUID="" rw rootwait
EOF
tee "$mountpoint"/boot/efi/loader/entries/kzl.conf << EOF
title   Ubuntu-KZL
linux   /vmlinuz-KZL
initrd  /initrd-KZL.img
options root=PARTUUID="" rw rootwait
EOF
# EFI: /boot/efi
blkid >> "$mountpoint"/boot/efi/loader/entries/ubuntu.conf
nano "$mountpoint"/boot/efi/loader/entries/ubuntu.conf
blkid >> "$mountpoint"/boot/efi/loader/entries/kzl.conf
nano "$mountpoint"/boot/efi/loader/entries/kzl.conf

# fstab
tee "$mountpoint"/etc/fstab << EOF
# Static information about the filesystems.
# See fstab(5) for details.

# <device> <target> <type> <options> <dump> <pass>

EOF
blkid >> "$mountpoint"/etc/fstab
nano "$mountpoint"/etc/fstab
