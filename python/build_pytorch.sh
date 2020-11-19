#!/bin/bash

set -e

# BUILDDIR=/tmps
BUILDDIR=/dev/shm

# PYTHONBIN=/usr/bin/python
PYTHONBIN=/usr/bin/python3
# PYTHONBIN=/usr/local/bin/python3.9

export CPPFLAGS="-D_FORTIFY_SOURCE=2"
export CFLAGS="-march=native -O2 -pipe -fstack-protector-strong -fno-plt"
export CXXFLAGS="-march=native -O2 -pipe -fstack-protector-strong -fno-plt"
export LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"

# tegra
export BUILD_BINARY=ON
export BUILD_TEST=OFF
export USE_FFMPEG=ON
export USE_GLOG=ON
export USE_NCCL=OFF
export USE_PYTORCH_QNNPACK=OFF
export USE_QNNPACK=OFF
export USE_XNNPACK=OFF
export USE_ZSTD=ON

export TORCH_BUILD_VERSION=1.7.0

# sudo pacman -Sy --needed --noconfirm ffmpeg gflags google-glog intel-mkl nccl lapack

sudo apt update
sudo apt install -y \
    nvidia-jetpack libgflags-dev libgoogle-glog-dev libnuma-dev libopenblas-dev libatlas-base-dev liblapack-dev libopenmpi-dev \
    libavcodec-dev libavformat-dev libavdevice-dev libavfilter-dev libavresample-dev libavutil-dev libpostproc-dev libswresample-dev libswscale-dev \
    zstd libzstd-dev

# sudo apt update
# sudo apt install -y libassuan-dev intel-mkl-full ffmpeg \
#     libgflags-dev libgoogle-glog-dev libnuma-dev libopenblas-dev libatlas-base-dev liblapack-dev libopenmpi-dev \
#     libavcodec-dev libavformat-dev libavdevice-dev libavfilter-dev libavresample-dev libavutil-dev libpostproc-dev libswresample-dev libswscale-dev

cd $BUILDDIR
if [ -d pytorch ]; then
    echo "\"$BUILDDIR/pytorch\" exists"
    exit 1
fi

git clone --recursive https://github.com/pytorch/pytorch.git
cd pytorch
git checkout v$TORCH_BUILD_VERSION
git submodule update --init --recursive

$PYTHONBIN -m pip install --user -U --no-binary :all: ninja
$PYTHONBIN -m pip install --user -U --no-binary :all: -r requirements.txt
$PYTHONBIN setup.py clean
TORCH_CUDA_ARCH_LIST="6.1" $PYTHONBIN setup.py bdist_wheel
# TORCH_CUDA_ARCH_LIST="6.1;6.2;7.0;7.0+PTX;7.2;7.2+PTX;7.5;7.5+PTX;8.6;8.6+PTX" $PYTHONBIN setup.py bdist_wheel
sudo mkdir -p /home/.repository/pip
sudo cp dist/*.whl /home/.repository/pip
$PYTHONBIN -m pip install -U --user /home/.repository/pip/torch-$TORCH_BUILD_VERSION*-*.whl

echo "#################################"
echo "   PyTorch build successfully.   "
echo "#################################"
