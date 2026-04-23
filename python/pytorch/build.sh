#!/usr/bin/env bash
#
# build.sh
#

set -e
set -o pipefail
set -u
# set -x

umask 0022

################################################################################

export PATH="/opt/bin:/usr/local/cuda/bin:$PATH"

PYTORCH_VERSION=v2.11.0

cd pytorch-$PYTORCH_VERSION

echo "${PYTORCH_VERSION/v/}" > version.txt

export BUILD_TEST=False

export PYTORCH_BUILD_VERSION="${PYTORCH_VERSION/v/}"
export PYTORCH_BUILD_NUMBER=0

export TORCH_CUDA_ARCH_LIST="7.5"

/opt/bin/python3 setup.py clean
CMAKE_ONLY=1 /opt/bin/python3 setup.py build > ../build.log 2>&1
ccmake build
cp -v build/CMakeCache.txt ../CMakeCache.txt

# /opt/bin/python3 setup.py build
# /opt/bin/python3 setup.py install --user
# /opt/bin/python3 setup.py bdist_wheel
/opt/bin/python3 -m pip -v wheel --wheel-dir ~/wheels --no-binary :all: --no-build-isolation .
/opt/bin/python3 -m pip -v install --user -U --no-index --find-links ~/wheels torch

cd ..
tar --zstd -cf pytorch-$PYTORCH_VERSION-build.tar.zst pytorch-$PYTORCH_VERSION

echo "Successfully built PyTorch $PYTORCH_VERSION"
