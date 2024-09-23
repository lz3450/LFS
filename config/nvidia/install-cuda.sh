workdir=/tmp/cuda
pkgname=cuda_12.4.1_550.54.15_linux.run
source=https://developer.download.nvidia.com/compute/cuda/12.4.1/local_installers/cuda_12.4.1_550.54.15_linux.run

set -e

if [ ! -f "$HOME/Downloads/$pkgname" ]; then
    wget -P $HOME/Downloads $source
fi

sudo rm -rf "$workdir"
mkdir -p "$workdir"
sudo bash $HOME/Downloads/$pkgname --tmpdir="$workdir"
