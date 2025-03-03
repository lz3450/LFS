#!/usr/bin/bash
#
# install-driver.sh
#

set -e

workdir=/tmp/nvidia
pkgname=nvidia
pkgver=565.77
source=https://us.download.nvidia.com/XFree86/Linux-x86_64/$pkgver/NVIDIA-Linux-x86_64-$pkgver.run
runfile="$HOME/Downloads/NVIDIA-Linux-x86_64-$pkgver.run"

if [[ ! -f "$runfile" ]]; then
    wget -P "$HOME/Downloads" "$source"
fi

sudo rm -rf "$workdir"
bash "$runfile" -A > driver-help.txt
bash "$runfile" --extract-only --target "$workdir"

cd "$workdir"
sudo ./nvidia-installer \
    --accept-license \
    --expert \
    --log-file-name="$HOME"/log/nvidia-driver-install.log \
    --kernel-name=$(uname -r) \
    --no-backup \
    --disable-nouveau \
    --no-distro-scripts \
    --no-wine-files \
    --no-dkms \
    --no-check-for-alternate-installs \
    --concurrency-level=$(nproc) \
    --install-libglvnd \
    --systemd \
    --no-rebuild-initramfs

sudo rm -vf /usr/lib/modprobe.d/nvidia-installer-disable-nouveau.conf
echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf
