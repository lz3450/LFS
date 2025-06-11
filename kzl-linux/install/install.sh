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
    wpa_supplicant
    zsh zsh-autosuggestions zsh-syntax-highlighting
    linux linux-firmware
)

pacstrap /mnt "${pkg_list[@]}"

fallocate -l 8G /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
if [ ! -f /swapfile ]; then
    ln -sf /mnt/swapfile /swapfile
    swapon /swapfile
fi

genfstab -U /mnt >> /mnt/etc/fstab

cp -rf initialize.sh kzl-linux.conf loader.conf /mnt/root
