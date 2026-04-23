#!/usr/bin/env bash
#
# prepare.sh
#

set -e
set -o pipefail
set -u
# set -x

umask 0022

################################################################################

PYTORCH_VERSION=v2.11.0

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
    -e '/cmake/d' \
    pyproject.toml

/opt/bin/python3 -m pip wheel --wheel-dir ~/wheels --no-binary :all: --group dev
/opt/bin/python3 -m pip install --user -U --no-index --find-links ~/wheels --group dev
/opt/bin/python3 -m pip wheel --wheel-dir ~/wheels mkl-static mkl-include
/opt/bin/python3 -m pip install --user -U --no-index --find-links ~/wheels mkl-static mkl-include

echo "${PYTORCH_VERSION/v/}" > version.txt

echo "Successfully prepared PyTorch $PYTORCH_VERSION for building"
