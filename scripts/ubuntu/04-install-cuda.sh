#!/usr/bin/env bash
#
# 04-install-cuda.sh
#

set -e

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 255
fi

. /etc/os-release
LOG_DIR="log/$UBUNTU_CODENAME"

pkgs=(
    nvidia-driver-580
    cuda-libraries-12-6
    cuda-toolkit-12-6
)

apt-get update
apt-get upgrade -y

wget -qO /tmp/cuda-keyring_1.1-1_all.deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
dpkg -i /tmp/cuda-keyring_1.1-1_all.deb
apt-get update
apt-get --no-install-recommends -s install "${pkgs[@]}" | grep "^Inst" | awk '{print $2}' | LC_ALL=C sort -n > "$LOG_DIR/cuda_to_install_pkgs.txt"
apt-get --no-install-recommends -y install "${pkgs[@]}"

echo "Successfully installed CUDA for Ubuntu $UBUNTU_CODENAME"
