pacstrap /mnt base linux linux-firmware zsh grml-zsh-config zsh-autosuggestions zsh-syntax-highlighting wpa_supplicant intel-ucode nano

fallocate -l 8G /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
if [ ! -f /swapfile ]; then
    ln -sf /mnt/swapfile /swapfile
    swapon /swapfile
fi

genfstab -U /mnt >> /mnt/etc/fstab

cp -rf initialize.sh kzl-linux.conf loader.conf /mnt/root
