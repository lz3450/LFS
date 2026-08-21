#!/usr/bin/env bash
#
# prepare.sh
#

set -Eeuo pipefail
# set -x

umask 0022

################################################################################

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly PYTORCH_VERSION=v2.11.0
readonly SOURCE_DIR="pytorch-${PYTORCH_VERSION}"
readonly SOURCE_ARCHIVE="${SOURCE_DIR}.tar.zst"
readonly WHEEL_DIR="${HOME}/wheels"

cd "${SCRIPT_DIR}"
mkdir -p "${WHEEL_DIR}"

if [[ ! -d "${SOURCE_DIR}" ]]; then
    if [[ ! -f "${SOURCE_ARCHIVE}" ]]; then
        git clone --depth 1 --branch "${PYTORCH_VERSION}" --recurse-submodules --shallow-submodules \
            https://github.com/pytorch/pytorch "${SOURCE_DIR}"
        tar --zstd -cf "${SOURCE_ARCHIVE}" "${SOURCE_DIR}"
    else
        tar -xf "${SOURCE_ARCHIVE}"
    fi
fi

cd "${SOURCE_DIR}"

# Use the system CMake/ccmake and omit the optional lint tool from the
# source-only wheelhouse. Keep the match limited to requirement entries so
# future pyproject.toml settings containing these words survive.
sed -i \
    -e '/^[[:space:]]*"lintrunner[;"]/d' \
    -e '/^[[:space:]]*"cmake[<=>]/d' \
    pyproject.toml

/opt/bin/python3 -m pip wheel --wheel-dir "${WHEEL_DIR}" --no-binary :all: --group dev
/opt/bin/python3 -m pip install --user --upgrade --no-index --find-links "${WHEEL_DIR}" --group dev
/opt/bin/python3 -m pip wheel --wheel-dir "${WHEEL_DIR}" mkl-static mkl-include
/opt/bin/python3 -m pip install --user --upgrade --no-index --find-links "${WHEEL_DIR}" mkl-static mkl-include

echo "${PYTORCH_VERSION#v}" > version.txt

echo "Successfully prepared PyTorch ${PYTORCH_VERSION} for building"
