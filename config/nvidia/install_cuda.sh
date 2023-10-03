workdir=/tmp/cuda
source=https://developer.download.nvidia.com/compute/cuda/11.7.1/local_installers/cuda_11.7.1_515.65.01_linux.run

set -e

if [ ! -f $HOME/Downloads/cuda_11.7.1_515.65.01_linux.run ]; then
    wget -P $HOME/Downloads $source
fi

sudo rm -rf "$workdir"
mkdir -p "$workdir"
sudo bash $HOME/Downloads/cuda_11.7.1_515.65.01_linux.run --tmpdir="$workdir"
