#!/bin/bash
# 
# build_pytorch.sh
# 

VERSION=1.0

# arguments/options

PLATFORM=
TORCH_VERSION=
PYTHONBIN=/usr/bin/python3
CLEAN=0
BUILDDIR=/tmp
CUDA_ARCH_LIST="6.1;6.2;7.0;7.0+PTX;7.2;7.2+PTX;7.5;7.5+PTX;8.6;8.6+PTX"

# functions

usage() {
    printf "build_pytorch %s\n" "$VERSION"
    echo
    printf "build_pytorch will build PyTorch from source.\n"
    echo
    printf "Usage: lfs-build -P platform -t torch_version [ -p python ] [ -C ]\n"
    echo
    echo "    -h, --help            display this help message and exit"
    echo "    -v, --version         display version information and exit"
    echo "    -P, --platform        platform (tegra, kzl-linux)"
    echo "    -t, --torch_version   pytorch version"
    echo "    -p, --python          python executable path"
    echo "    -C, --clear           run \"setup.py clean\""
    echo
}

# program start

set -e -u -o pipefail
# set -x

umask 0022

while (( "$#" )); do
    case "$1" in
        -h|--help)              usage; exit 0 ;;
        -v|--version)           printf "$VERSION"; exit 0 ;;
        -P|--platform)          shift; PLATFORM="$1" ;;
        -t|--torch_version)     shift; TORCH_VERSION="$1" ;;
        -p|--python)            shift; PYTHONBIN="$1" ;;
        -C|--clean)             CLEAN=1 ;;
        *)                      printf "unknown option \"$1\""; exit 1 ;;
    esac
    shift
done

export CPPFLAGS="-D_FORTIFY_SOURCE=2"
export CFLAGS="-march=native -O2 -pipe -fstack-protector-strong -fno-plt"
export CXXFLAGS="-march=native -O2 -pipe -fstack-protector-strong -fno-plt"
export LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"

# common
export BUILD_BINARY=ON
export BUILD_TEST=OFF
export USE_FFMPEG=ON
export USE_GFLAGS=ON
export USE_GLOG=ON

export TORCH_BUILD_VERSION=$TORCH_VERSION

if [ $PLATFORM = "kzl-linux" ]; then

export USE_SYSTEM_NCCL=ON
export USE_MKLDNN_CBLAS=ON

    sudo pacman -Sy --needed --noconfirm \
        ffmpeg \
        gflags \
        google-glog \
        intel-mkl \
        nccl \
        lapack \
        openmpi
elif [ $PLATFORM = "tegra" ]; then

BUILDDIR=/dev/shm
CUDA_ARCH_LIST="6.2"
export USE_NCCL=OFF
export USE_PYTORCH_QNNPACK=OFF
export USE_QNNPACK=OFF
export USE_TENSORRT=ON
export USE_XNNPACK=OFF
export USE_ZSTD=ON

    sudo apt update
    sudo apt install -y \
        nvidia-jetpack \
        libgflags-dev \
        libgoogle-glog-dev \
        libnuma-dev \
        libopenblas-dev \
        libatlas-base-dev \
        liblapack-dev \
        libopenmpi-dev \
        libavcodec-dev \
        libavformat-dev \
        libavdevice-dev \
        libavfilter-dev \
        libavresample-dev \
        libavutil-dev \
        libpostproc-dev \
        libswresample-dev \
        libswscale-dev \
        zstd libzstd-dev
else
    printf "unknown platform \"$1\""
    exit 1
fi

# sudo apt update
# sudo apt install -y libassuan-dev intel-mkl-full ffmpeg \
#     libgflags-dev libgoogle-glog-dev libnuma-dev libopenblas-dev libatlas-base-dev liblapack-dev libopenmpi-dev \
#     libavcodec-dev libavformat-dev libavdevice-dev libavfilter-dev libavresample-dev libavutil-dev libpostproc-dev libswresample-dev libswscale-dev

cd $BUILDDIR
if [ ! -d pytorch ]; then
    git clone --recursive https://github.com/pytorch/pytorch.git
fi

cd pytorch
git checkout v$TORCH_BUILD_VERSION
git submodule update --init --recursive

$PYTHONBIN -m pip install --user -U --no-binary :all: ninja
$PYTHONBIN -m pip install --user -U --no-binary :all: -r requirements.txt

if (( CLEAN )); then
    $PYTHONBIN setup.py clean
fi

TORCH_CUDA_ARCH_LIST=$CUDA_ARCH_LIST $PYTHONBIN setup.py bdist_wheel
sudo mkdir -p /home/.repository/pip
sudo cp dist/*.whl /home/.repository/pip

echo "################################################################################"
echo "  PyTorch build successfully."
echo "################################################################################"
