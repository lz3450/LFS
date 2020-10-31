#!/bin/bash

set -e

ROOTDIR=/tmp

export BUILD_BINARY=ON
export BUILD_CUSTOM_PROTOBUF=ON
export BUILD_DOCS=OFF
export BUILD_PYTHON=True
export BUILD_CAFFE2_OPS=ON
export BUILD_SHARED_LIBS=ON
export BUILD_TEST=False
export BUILD_JNI=OFF
export USE_CUDA=ON
export USE_CUDNN=ON
export CUDA_HOME=/opt/cuda
export CUDNN_LIB_DIR=/usr/lib
export CUDNN_INCLUDE_DIR=/usr/include
export TORCH_NVCC_FLAGS="-Xfatbin -compress-all"
export CUDAHOSTCXX=g++
export USE_SYSTEM_NCCL=ON
export USE_FFMPEG=ON
export USE_GFLAGS=ON
export USE_GLOG=ON
export USE_MKLDNN=ON
export USE_MKLDNN_CBLAS=ON
export USE_SYSTEM_NCCL=ON
export USE_NUMPY=ON
export USE_OPENCL=OFF
export USE_OPENCV=OFF

export PYTORCH_BUILD_VERSION="1.7.0"
export PYTORCH_BUILD_NUMBER=1

export CPPFLAGS="-D_FORTIFY_SOURCE=2"
export CFLAGS="-march=native -O2 -pipe -fstack-protector-strong -fno-plt"
export CXXFLAGS="-march=native -O2 -pipe -fstack-protector-strong -fno-plt"
export LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"

sudo pacman -Sy --needed --noconfirm ffmpeg gflags google-glog intel-mkl nccl lapack

cd $ROOTDIR
if [ -d pytorch ]; then
    sudo rm -rf pytorch
fi

git clone https://github.com/pytorch/pytorch.git -b v$PYTORCH_BUILD_VERSION --recursive
cd pytorch
git submodule update --init --recursive

# pytorch
sudo pip install --no-binary :all: -r requirements.txt
TORCH_CUDA_ARCH_LIST="6.1;6.2;7.0;7.0+PTX;7.2;7.2+PTX;7.5;7.5+PTX;8.6;8.6+PTX" python setup.py bdist_wheel
sudo mkdir -p /home/.repository/pip
sudo cp dist/*.whl /home/.repository/pip
pip install -U --user /home/.repository/pip/torch-$PYTORCH_BUILD_VERSION-*-linux_aarch64.whl

echo "#################################"
echo " PyTorch built successfully. "
echo "#################################"
