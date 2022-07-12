workdir=/tmp/nvidia
pkgname=nvidia
pkgver=515.57
source=https://us.download.nvidia.com/XFree86/Linux-x86_64/$pkgver/NVIDIA-Linux-x86_64-$pkgver.run

set -e

mkdir -p $workdir
cd $workdir

if [ ! -f NVIDIA-Linux-x86_64-$pkgver.run ]; then
    wget $source
fi

if [ -d NVIDIA-Linux-x86_64-$pkgver ]; then
    sudo rm -rf NVIDIA-Linux-x86_64-$pkgver
fi

if [ -d install.log ]; then
    sudo rm -rf install.log
fi

bash NVIDIA-Linux-x86_64-$pkgver.run --extract-only
cd NVIDIA-Linux-x86_64-$pkgver

sudo ./nvidia-installer \
    --accept-license \
    --expert \
    --log-file-name=$workdir/install.log \
    --no-precompiled-interface \
    --no-backup \
    --no-distro-scripts \
    --no-wine-files \
    --no-kernel-module-source \
    --no-check-for-alternate-installs \
    -j 8 \
    --force-libglx-indirect

# printf "%s" "blacklist nouveau" | sudo install -Dm644 /dev/stdin /etc/modprobe.d/nouveau_blacklist.conf
