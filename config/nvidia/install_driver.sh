workdir=/tmp/nvidia
pkgname=nvidia
pkgver=525.116.04
source=https://us.download.nvidia.com/XFree86/Linux-x86_64/$pkgver/NVIDIA-Linux-x86_64-$pkgver.run

set -e

mkdir -p $workdir
cd $workdir

if [ ! -f NVIDIA-Linux-x86_64-$pkgver.run ]; then
    wget $source
fi

if [ -d install.log ]; then
    sudo rm -rf install.log
fi

bash NVIDIA-Linux-x86_64-$pkgver.run --extract-only
cd NVIDIA-Linux-x86_64-$pkgver

sudo ./nvidia-installer \
    --accept-license \
    --expert \
    --log-file-name=$HOME/nvidia-driver-install.log

# printf "%s" "blacklist nouveau" | sudo install -Dm644 /dev/stdin /etc/modprobe.d/nouveau_blacklist.conf
