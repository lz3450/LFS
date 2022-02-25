ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
hwclock --systohc

read -p 'hostname: ' HOSTNAME
echo $HOSTNAME > /etc/hostname

# passwd
echo "root password:"
passwd

useradd -m -U -G wheel -s /bin/zsh kzl
echo "kzl password:"
passwd kzl

# zsh
echo 'source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh' | tee -a /etc/zsh/zshrc
echo 'source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' | tee -a /etc/zsh/zshrc

# locale
sed -i '/^#en_US.UTF-8/s/^#//' /etc/locale.gen
sed -i '/^#zh_CN.UTF-8/s/^#//' /etc/locale.gen
echo 'LANG=en_US.UTF-8' | tee -a /etc/locale.conf
locale-gen

# bootctl
bootctl --path=/boot install
cat loader.conf >> /boot/loader/loader.conf
nano /boot/loader/loader.conf
cp archlinux.conf /boot/loader/entries
blkid >> /boot/loader/entries/kzl-linux.conf
nano /boot/loader/entries/kzl-linux.conf

# efistub
# blkid >> /root/efi.sh
# nano /root/efi.sh
# bash /root/efi.sh
