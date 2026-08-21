#!/usr/bin/env bash
#
# build.sh
#

set -Eeuo pipefail
# set -x

umask 0022

################################################################################

export PATH="/opt/bin:/usr/local/cuda/bin:${PATH}"

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly PYTORCH_VERSION=v2.11.0
readonly PACKAGE_VERSION="${PYTORCH_VERSION#v}"
readonly SOURCE_DIR="pytorch-${PYTORCH_VERSION}"
readonly WHEEL_DIR="${HOME}/wheels"

cd "${SCRIPT_DIR}/${SOURCE_DIR}"
mkdir -p "${WHEEL_DIR}"

echo "${PACKAGE_VERSION}" > version.txt

# export MAX_JOBS=16

export BUILD_TEST=False

export PYTORCH_BUILD_VERSION="${PACKAGE_VERSION}"
export PYTORCH_BUILD_NUMBER=0

export TORCH_CUDA_ARCH_LIST="7.5"

/opt/bin/python3 setup.py clean
rm -rf build
CMAKE_ONLY=1 /opt/bin/python3 setup.py build > "${SCRIPT_DIR}/build.log" 2>&1
ccmake build
cp -v build/CMakeCache.txt "${SCRIPT_DIR}/CMakeCache.txt"

/opt/bin/python3 -m pip --verbose wheel --wheel-dir "${WHEEL_DIR}" --no-deps --no-build-isolation .
/opt/bin/python3 -m pip --verbose install --user --force-reinstall --no-deps --no-index \
    --find-links "${WHEEL_DIR}" "torch==${PACKAGE_VERSION}"

cd "${SCRIPT_DIR}"
tar --zstd -cf "${SOURCE_DIR}-build.tar.zst" "${SOURCE_DIR}"

echo "Successfully built PyTorch ${PYTORCH_VERSION}"
