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

DRIVER_VERSION=580.105.08

WORKDIR=/tmp/nvidia
DOWNLOADS_DIR="$HOME/Downloads"
# LOG_FILE="$SCRIPT_DIR/driver-install-${DRIVER_VERSION%%.*}.log"
# HELP_TXT="driver-help-${DRIVER_VERSION%%.*}.txt"
LOG_FILE="$SCRIPT_DIR/driver-install.log"
HELP_TXT="driver-help.txt"

RUNFILE=NVIDIA-Linux-x86_64-$DRIVER_VERSION.run

################################################################################

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
    --kernel-name="$(uname -r)" \
    --no-backup \
    --disable-nouveau \
    --no-distro-scripts \
    --no-wine-files \
    --no-dkms \
    --no-check-for-alternate-installs \
    --concurrency-level="$(nproc)" \
    --install-libglvnd \
    --systemd \
    --no-rebuild-initramfs

sudo rm -vf /usr/lib/modprobe.d/nvidia-installer-disable-nouveau.conf
echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf

sudo chown "$(id -u):$(id -g)" "$LOG_FILE"
sed -i '/-> Building kernel modules/,/-> done\./{/-> Building kernel modules/b;/-> done\./b;d}' "$LOG_FILE"
sed -i '/-> Kernel messages:/,/-> X installation prefix/{/-> Kernel messages:/b;/-> X installation prefix/b;d}' "$LOG_FILE"


if [[ -f "$SCRIPT_DIR/nvidia-uninstall.log" ]]; then
    sudo chown "$(id -u):$(id -g)" "$SCRIPT_DIR/nvidia-uninstall.log"
    # mv "$SCRIPT_DIR/nvidia-uninstall.log" "$SCRIPT_DIR/driver-uninstall-${DRIVER_VERSION%%.*}.log"
    mv "$SCRIPT_DIR/nvidia-uninstall.log" "$SCRIPT_DIR/driver-uninstall.log"
fi
