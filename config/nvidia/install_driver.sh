# workdir=/tmp/nvidia
# pkgname=nvidia
# pkgver=510.54
# source=https://us.download.nvidia.com/XFree86/Linux-x86_64/$pkgver/NVIDIA-Linux-x86_64-$pkgver.run

# mkdir $workdir
# cd $workdir

# if [ ! -f NVIDIA-Linux-x86_64-$pkgver.run ]; then
#     wget $source
# fi

# bash NVIDIA-Linux-x86_64-$pkgver.run --extract-only
# cd NVIDIA-Linux-x86_64-$pkgver

# sudo ./nvidia-installer \
#     --accept-license \
#     --expert \
#     --log-file-name=$workdir/install.log \
#     --no-precompiled-interface \
#     --no-backup \
#     --no-distro-scripts \
#     --no-wine-files \
#     --no-kernel-module-source \
#     --no-check-for-alternate-installs \
#     -j 8 \
#     --force-libglx-indirect

printf "%s" "blacklist nouveau" | sudo install -Dm644 /dev/stdin /etc/modprobe.d/nouveau_blacklist.conf
