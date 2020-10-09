#!/bin/bash

set -e

ROOTDIR=/dev/shm

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
export CUDAHOSTCXX=g++-9
export USE_FFMPEG=ON
export USE_GFLAGS=ON
export USE_GLOG=ON
export USE_MKL=ON
export USE_MKLDNN=ON
export USE_SYSTEM_NCCL=ON
export USE_NUMPY=ON
export USE_OPENCL=OFF
export USE_OPENCV=ON

export PYTORCH_BUILD_VERSION="1.6.0"
export PYTORCH_BUILD_NUMBER=1

sudo pacman -Sy ffmpeg gflags google-glog intel-mkl opencv 

cd $ROOTDIR
git clone https://github.com/pytorch/pytorch.git -b v$PYTORCH_BUILD_VERSION
cd pytorch
git submodule update --init --recursive

sudo pip install --force-reinstall --ignore-installed --no-binary :all: -r requirements.txt
TORCH_CUDA_ARCH_LIST="6.1" python setup.py build
python setup.py install --user
