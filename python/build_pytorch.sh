#!/bin/bash

set -e

# ROOTDIR=/tmps
ROOTDIR=/dev/shm

# PYTHONBIN=/usr/bin/python
# PIPBIN=/usr/bin/pip
PYTHONBIN=/usr/bin/python3
PIPBIN=/usr/bin/pip3
# PYTHONBIN=/usr/local/bin/python3.9
# PIPBIN=/usr/local/bin/pip3.9

export TORCH_BUILD_VERSION=1.7.0

export BUILD_BINARY=ON
export BUILD_CAFFE2_OPS=ON
export BUILD_CUSTOM_PROTOBUF=ON
export BUILD_DOCS=OFF
export BUILD_JNI=OFF
export BUILD_PYTHON=True
export BUILD_SHARED_LIBS=ON
export BUILD_TEST=False
export CUDA_HOME=/opt/cuda
export CUDNN_INCLUDE_DIR=/usr/include
export CUDNN_LIBRARY=/usr/lib
export USE_CUDA=ON
export USE_CUDNN=ON
export USE_FFMPEG=ON
export USE_GFLAGS=ON
export USE_GLOG=ON
export USE_MKLDNN=ON
export USE_MKLDNN_CBLAS=ON
export USE_NNPACK=OFF
export USE_NUMPY=True
export USE_OPENCL=OFF
export USE_OPENCV=OFF
export USE_PYTORCH_QNNPACK=OFF
export USE_QNNPACK=OFF
export USE_SYSTEM_NCCL=ON

export CPPFLAGS="-D_FORTIFY_SOURCE=2"
export CFLAGS="-march=native -O2 -pipe -fstack-protector-strong -fno-plt"
export CXXFLAGS="-march=native -O2 -pipe -fstack-protector-strong -fno-plt"
export LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"

# sudo pacman -Sy --needed --noconfirm ffmpeg gflags google-glog intel-mkl nccl lapack

# tegra
BUILD_BINARY=ON
USE_FFMPEG=ON
USE_GLOG=ON
USE_NCCL=OFF
USE_PYTORCH_QNNPACK=OFF
USE_QNNPACK=OFF
USE_ZSTD=ON

sudo apt update
sudo apt install -y \
    nvidia-jetpack libgflags-dev libgoogle-glog-dev libnuma-dev libopenblas-dev libatlas-base-dev liblapack-dev libopenmpi-dev \
    libavcodec-dev libavformat-dev libavdevice-dev libavfilter-dev libavresample-dev libavutil-dev libpostproc-dev libswresample-dev libswscale-dev \
    zstd libzstd-dev

# sudo apt update
# sudo apt install -y libassuan-dev intel-mkl-full ffmpeg \
#     libgflags-dev libgoogle-glog-dev libnuma-dev libopenblas-dev libatlas-base-dev liblapack-dev libopenmpi-dev \
#     libavcodec-dev libavformat-dev libavdevice-dev libavfilter-dev libavresample-dev libavutil-dev libpostproc-dev libswresample-dev libswscale-dev

cd $ROOTDIR
if [ ! -d pytorch ]; then
    git clone https://github.com/pytorch/pytorch.git -b v$TORCH_BUILD_VERSION --recursive
fi

cd pytorch
git submodule update --init --recursive

$PIPBIN install --user -U --no-binary :all: ninja
$PIPBIN install --user -U --no-binary :all: -r requirements.txt
$PYTHONBIN setup.py clean
TORCH_CUDA_ARCH_LIST="6.1;6.2;7.0;7.0+PTX;7.2;7.2+PTX;7.5;7.5+PTX;8.6;8.6+PTX" $PYTHONBIN setup.py bdist_wheel
sudo mkdir -p /home/.repository/pip
sudo cp dist/*.whl /home/.repository/pip
$PIPBIN install -U --user /home/.repository/pip/torch-$TORCH_BUILD_VERSION*-*.whl

echo "#################################"
echo "   PyTorch build successfully.   "
echo "#################################"
