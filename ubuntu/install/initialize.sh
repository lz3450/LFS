#! /bin/sh

cat > /etc/apt/sources.list << EOF
deb http://us.archive.ubuntu.com/ubuntu jammy main restricted universe
deb-src http://us.archive.ubuntu.com/ubuntu jammy main restricted universe

deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted
deb-src http://security.ubuntu.com/ubuntu/ jammy-security main restricted

deb http://us.archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe
deb-src http://us.archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe
EOF

apt update

apt install -y \
    zsh \
    wget \
    nano \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    f2fs-tools
wget -O .zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc

fallocate -l 16G /mnt/swapfile
mkswap /mnt/swapfile
chmod 600 /mnt/swapfile

dpkg-reconfigure locales
dpkg-reconfigure tzdata

read -p 'hostname: ' HOSTNAME
echo $HOSTNAME > /etc/hostname

nano /etc/hosts

bootctl install --esp-path=/boot/efi

cat > /boot/loader/loader.conf << EOF
timeout 3
console-mode max
default ubuntu
EOF

cat > /boot/loader/entries/ubuntu.conf << EOF
title   Ubuntu 22.04
linux   /vmlinuz
initrd  /initrd.img
options root=
EOF

blkid >> /boot/loader/entries/ubuntu.conf

nano /boot/loader/entries/ubuntu.conf

# passwd
echo "root password:"
passwd

useradd -m -U -G wheel -s /bin/zsh kzl
echo "kzl password:"
passwd kzl

# zsh
echo 'source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh' | tee -a /root/.zshrc
echo 'source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' | tee -a /root/.zshrc
echo 'source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh' | sudo -u kzl tee -a /home/kzl/.zshrc
echo 'source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' | sudo -u kzl tee -a /home/kzl/.zshrc

# environment variables
cat > ~/.zshenv << EOF 
typeset -U PATH path
path=("$HOME/.local/bin" "\$path[@]")
export PATH
fpath=(/usr/local/share/zsh/site-functions $fpath)
EOF
