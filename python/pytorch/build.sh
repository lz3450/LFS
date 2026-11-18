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
readonly PYTORCH_VERSION=v2.14.1
readonly PACKAGE_VERSION="${PYTORCH_VERSION#v}"
readonly SOURCE_DIR="pytorch-${PYTORCH_VERSION}"
readonly WHEEL_DIR="${HOME}/wheels"

if [[ ! -d "${SCRIPT_DIR}/${SOURCE_DIR}" ]]; then
    echo "error: ${SOURCE_DIR} not found, run prepare.sh first" >&2
    exit 1
fi

cd "${SCRIPT_DIR}/${SOURCE_DIR}"
mkdir -p "${WHEEL_DIR}"

echo "${PACKAGE_VERSION}" > version.txt

# export MAX_JOBS=16

export BUILD_TEST=0

export PYTORCH_BUILD_VERSION="${PACKAGE_VERSION}"
export PYTORCH_BUILD_NUMBER=0

export TORCH_CUDA_ARCH_LIST="7.5"

# PyTorch 2.14 builds through scikit-build-core (PEP 517): `setup.py clean` and
# CMAKE_ONLY=1 `setup.py build` are gone. Set CMake options through the
# environment (see cmake/EnvVarForwarding.cmake) or with
# `-C cmake.define.<VAR>=<VALUE>` on the pip command instead of ccmake.
rm -rf build

/opt/bin/python3 -m pip --verbose wheel --wheel-dir "${WHEEL_DIR}" --no-deps --no-build-isolation .
cp -v build/CMakeCache.txt "${SCRIPT_DIR}/CMakeCache.txt"

/opt/bin/python3 -m pip --verbose install --user --force-reinstall --no-deps --no-index \
    --find-links "${WHEEL_DIR}" "torch==${PACKAGE_VERSION}"

cd "${SCRIPT_DIR}"
tar --zstd -cf "${SOURCE_DIR}-build.tar.zst" "${SOURCE_DIR}"

echo "Successfully built PyTorch ${PYTORCH_VERSION}"
