workdir=/tmp/nvidia
pkgname=nvidia
pkgver=535.86.05
source=https://us.download.nvidia.com/XFree86/Linux-x86_64/$pkgver/NVIDIA-Linux-x86_64-$pkgver.run

set -e

if [ ! -f $HOME/Downloads/NVIDIA-Linux-x86_64-$pkgver.run ]; then
    wget -P $HOME/Downloads $source
fi

sudo rm -rf $workdir
bash $HOME/Downloads/NVIDIA-Linux-x86_64-$pkgver.run --extract-only --target $workdir
cd $workdir

sudo ./nvidia-installer \
    --accept-license \
    --expert \
    --no-install-compat32-libs \
    --log-file-name=$HOME/nvidia-driver-install.log \
    --run-nvidia-xconfig \
    --no-dkms \
    --no-check-for-alternate-installs \
    -j $(nproc)

# printf "%s" "blacklist nouveau" | sudo install -Dm644 /dev/stdin /etc/modprobe.d/nouveau_blacklist.conf
