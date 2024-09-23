workdir=/tmp/cudnn
pkgname=cudnn-linux-x86_64-8.9.7.29_cuda12-archive.tar.xz

set -e

if [ ! -f "$HOME/Downloads/$pkgname" ]; then
    echo "Please download $pkgname from https://developer.nvidia.com/cudnn"
fi

sudo rm -rf "$workdir"
mkdir -p "$workdir"
tar -xf $HOME/Downloads/$pkgname -C "$workdir"

sudo cp "$workdir"/cudnn-*-archive/include/cudnn*.h /usr/local/cuda/include
sudo cp -P "$workdir"/cudnn-*-archive/lib/libcudnn* /usr/local/cuda/lib64
sudo chmod a+r /usr/local/cuda/include/cudnn*.h /usr/local/cuda/lib64/libcudnn*
