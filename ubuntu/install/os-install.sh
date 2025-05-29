#!/bin/bash
#
# os-install.sh
#

set -e

# ubuntu_mirror="http://us.archive.ubuntu.com/ubuntu/"
ubuntu_mirror="https://mirror.arizona.edu/ubuntu/"

mountpoint="/mnt"
debootstrap_suite="noble"
common_deb_pkgs=(
    ### general
    sudo
    nano
    bash-completion
    zsh zsh-syntax-highlighting zsh-autosuggestions
    build-essential
    ### disk
    parted fdisk
    ### network
    wpasupplicant
    wget curl
    openssh-server
    git
    ### kernel
    linux-image-generic
    # dracut
    initramfs-tools
    ### pacman
    libarchive-tools
    zstd
    libgpgme-dev
    fakeroot
)
noble_deb_pkgs=(
    systemd-boot
    systemd-resolved
)
questing_deb_pkgs=(
    systemd-boot-efi
    systemd-boot
    systemd-resolved
)
exclude_pkgs=(
    ubuntu-minimal
    ubuntu-pro-client
    ubuntu-pro-client-l10n
)
declare -a deb_pkgs


if (($# != 1)); then
    echo "Usage: $0 <suite>"
    exit 1
fi

debootstrap_suite="$1"
case "$debootstrap_suite" in
    jammy)
        deb_pkgs=("${common_deb_pkgs[@]}")
        ;;
    noble)
        deb_pkgs=("${common_deb_pkgs[@]}" "${noble_deb_pkgs[@]}")
        ;;
    questing)
        deb_pkgs=("${common_deb_pkgs[@]}" "${questing_deb_pkgs[@]}")
        ;;
    *)
        echo "Unknown suite \"$debootstrap_suite\""
        exit 1
        ;;
esac

# debootstrap
debootstrap \
    --arch="amd64" \
    --include="$(IFS=',' echo "${deb_pkgs[*]}")" \
    --exclude="$(IFS=',' echo "${exclude_pkgs[*]}")" \
    --components=main,restricted,universe \
    --merged-usr \
    "$debootstrap_suite" \
    "$mountpoint" \
    "$ubuntu_mirror"

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

# modernized sources, for future use
# tee "$mountpoint"/etc/apt/sources.list.d/ubuntu.sources << EOF
# Types: deb deb-src
# URIs: https://mirror.arizona.edu/ubuntu/
# Suites: $debootstrap_suite
# Components: main restricted universe
# Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
# EOF

# pacman
if [[ -f "/opt/bin/pacman" ]]; then
    install -d -m 0755 "$mountpoint/var/lib/pacman/"
    pacman -Sy -r "$mountpoint" --noconfirm --cachedir /home/.repository/ubuntu pacman linux
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

cp os-config.sh "$mountpoint"/root

# Assume that LFS located at "/home/LFS"
./lfs-chroot "$mountpoint" /bin/bash

# boot
mkdir -p "$mountpoint"/boot/efi/loader/entries
tee "$mountpoint"/boot/efi/loader/loader.conf << EOF
timeout 3
console-mode max
default ubuntu.conf
EOF
tee "$mountpoint"/boot/efi/loader/entries/ubuntu.conf << EOF
title   Ubuntu
linux   vmlinuz
initrd  initrd.img
options root=PARTUUID= rw rootwait
EOF
tee "$mountpoint"/boot/efi/loader/entries/kzl.conf << EOF
title   Ubuntu-KZL
linux   vmlinuz-KZL
#initrd  initrd-KZL.img
options root=PARTUUID= rw rootwait
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

PARTUUID=           /               f2fs            defaults        0 1
PARTUUID=           /boot/efi       vfat            umask=0077      0 2
/swapfile           none            swap            defaults        0 0

EOF
blkid >> "$mountpoint"/etc/fstab
nano "$mountpoint"/etc/fstab

echo "Successfully installed Ubuntu $debootstrap_suite at $mountpoint"
