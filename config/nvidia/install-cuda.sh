workdir=/tmp/cuda
pkgver="12.4.1"
pkgname="cuda_${pkgver}_550.54.15_linux.run"
source=https://developer.download.nvidia.com/compute/cuda/$pkgver/$pkgname

set -e

if [ ! -f "$HOME/Downloads/$pkgname" ]; then
    wget -P $HOME/Downloads $source
fi

sudo rm -rf "$workdir"
mkdir -p "$workdir"
sudo bash $HOME/Downloads/$pkgname --tmpdir="$workdir"
