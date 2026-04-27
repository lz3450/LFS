#!/bin/bash
#
# install-driver.sh
#

set -e
set -o pipefail
set -u
# set -x

umask 0022

SCRIPT_NAME="$(basename "$0")"
SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

################################################################################

DRIVER_VERSION=580.142

WORKDIR=/tmp/nvidia
DOWNLOADS_DIR="$HOME/Downloads"
# LOG_FILE="$SCRIPT_DIR/driver-install-${DRIVER_VERSION%%.*}.log"
# HELP_TXT="driver-help-${DRIVER_VERSION%%.*}.txt"
LOG_FILE="$SCRIPT_DIR/driver-install.log"
HELP_TXT="driver-help.txt"

RUNFILE=NVIDIA-Linux-x86_64-$DRIVER_VERSION.run

################################################################################

if (( $# != 1 )); then
    echo "Usage: $SCRIPT_NAME <kernel-version>"
    exit 1
fi

KERNEL_VERSION="$1"

if [[ ! -f "$DOWNLOADS_DIR/$RUNFILE" ]]; then
    wget -P "$DOWNLOADS_DIR" https://us.download.nvidia.com/XFree86/Linux-x86_64/$DRIVER_VERSION/$RUNFILE
fi

./install-dependencies.sh

sudo rm -rf "$WORKDIR"
bash "$DOWNLOADS_DIR/$RUNFILE" -A > "$HELP_TXT"
bash "$DOWNLOADS_DIR/$RUNFILE" --extract-only --target "$WORKDIR"

cd "$WORKDIR"
sudo ./nvidia-installer \
    --accept-license \
    --expert \
    --log-file-name="$LOG_FILE" \
    --kernel-name="$KERNEL_VERSION" \
    --no-backup \
    --no-x-check \
    --disable-nouveau \
    --no-distro-scripts \
    --no-wine-files \
    --no-kernel-module-source \
    --no-dkms \
    --no-check-for-alternate-installs \
    --concurrency-level="$(nproc)" \
    --install-libglvnd \
    --systemd \
    --skip-depmod \
    --kernel-module-type=open \
    --allow-installation-with-running-driver \
    --no-rebuild-initramfs \
    --silent

sudo rm -vf /usr/lib/modprobe.d/nvidia-installer-disable-nouveau.conf
echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf

sudo chown "$(id -u):$(id -g)" "$LOG_FILE"
sed -i '/-> Building kernel modules/,/-> done\./{/-> Building kernel modules/b;/-> done\./b;d}' "$LOG_FILE"
sed -i '/-> Kernel messages:/,/-> X installation prefix/{/-> Kernel messages:/b;/-> X installation prefix/b;d}' "$LOG_FILE"
sed -i \
    -e '/^creation time:/d' \
    -e 's|\(/tmp/template-\)[A-Za-z0-9]\{6\}|\1|' \
    -e 's|[0-9]+\.[0-9]+\.[0-9]+-KZL|x.y.z|g' \
    "$LOG_FILE"

if [[ -f "$SCRIPT_DIR/nvidia-uninstall.log" ]]; then
    sudo chown "$(id -u):$(id -g)" "$SCRIPT_DIR/nvidia-uninstall.log"
    # mv "$SCRIPT_DIR/nvidia-uninstall.log" "$SCRIPT_DIR/driver-uninstall-${DRIVER_VERSION%%.*}.log"
    mv "$SCRIPT_DIR/nvidia-uninstall.log" "$SCRIPT_DIR/driver-uninstall.log"
    sed -i -e '/^creation time:/d' "$SCRIPT_DIR/driver-uninstall.log"
fi
