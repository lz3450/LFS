#!/bin/bash
#
# build.sh
#

set -e
set -o pipefail
set -u
# set -x

umask 0022

################################################################################

PYTORCH_VERSION=v2.8.0

export PATH="/opt/bin:/usr/local/cuda/bin:$PATH"

if [[ ! -d "pytorch" ]]; then
    git clone --depth 10 -b $PYTORCH_VERSION --recurse-submodules --shallow-submodules https://github.com/pytorch/pytorch
    cd pytorch
    git submodule sync
else
    cd pytorch
    rm -rf build tmp
fi

sed -i \
    -e '/cmake/d' \
    -e '/lintrunner/d' \
    -e '/setuptools/d' \
    requirements.txt
python3 -m pip wheel --wheel-dir ~/wheels --no-binary :all: -r requirements.txt
python3 -m pip install --user -U --no-index --find-links ~/wheels -r requirements.txt

CMAKE_ONLY=1 python3 setup.py build > ../build.log 2>&1
ccmake build
python3 -m pip -v wheel --no-build-isolation .
