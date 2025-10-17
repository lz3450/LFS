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

PYTORCH_VERSION=v2.9.0

if [[ ! -d "pytorch-$PYTORCH_VERSION" ]]; then
    if [[ ! -f "pytorch-$PYTORCH_VERSION.tar.zst" ]]; then
        git clone --depth 10 -b $PYTORCH_VERSION --recurse-submodules --shallow-submodules https://github.com/pytorch/pytorch pytorch-$PYTORCH_VERSION
        tar --zstd -cf pytorch-$PYTORCH_VERSION.tar.zst pytorch-$PYTORCH_VERSION
    else
        tar -xf pytorch-$PYTORCH_VERSION.tar.zst
    fi
fi

cd pytorch-$PYTORCH_VERSION

sed -i \
    -e '/lintrunner/d' \
    pyproject.toml

python3 -m pip wheel --wheel-dir ~/wheels --no-binary :all: --group dev
python3 -m pip install --user -U --no-index --find-links ~/wheels --group dev
python3 -m pip wheel --wheel-dir ~/wheels --no-binary :all: --only-binary mkl-static,intel-openmp,tbb,mkl-include mkl-static
python3 -m pip install --user -U --no-index --find-links ~/wheels mkl-static

# CMAKE_ONLY=1 python3 setup.py build > ../build.log 2>&1
# ccmake build
python3 -m pip -v wheel --wheel-dir ~/wheels --no-binary :all: --no-build-isolation .
tar --zstd -cf pytorch-$PYTORCH_VERSION-build.tar.zst pytorch-$PYTORCH_VERSION
