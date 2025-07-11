#!/usr/bin/bash
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

DRIVER_VERSION=550.163.01

WORKDIR=/tmp/nvidia
DOWNLOADS_DIR="$HOME/Downloads"
LOG_FILE="$SCRIPT_DIR/nvidia-driver-install-${DRIVER_VERSION%%.*}.log"

RUNFILE=NVIDIA-Linux-x86_64-$DRIVER_VERSION.run

################################################################################

if [[ ! -f "$DOWNLOADS_DIR/$RUNFILE" ]]; then
    wget -P "$DOWNLOADS_DIR" https://us.download.nvidia.com/XFree86/Linux-x86_64/$DRIVER_VERSION/$RUNFILE
fi

# sudo rm -rf "$WORKDIR"
# bash "$DOWNLOADS_DIR/$RUNFILE" -A > driver-help-${DRIVER_VERSION%%.*}.txt
# bash "$DOWNLOADS_DIR/$RUNFILE" --extract-only --target "$WORKDIR"

# cd "$WORKDIR"
# sudo ./nvidia-installer \
#     --accept-license \
#     --expert \
#     --log-file-name="$LOG_FILE" \
#     --kernel-name="$(uname -r)" \
#     --no-backup \
#     --disable-nouveau \
#     --no-distro-scripts \
#     --no-wine-files \
#     --no-dkms \
#     --no-check-for-alternate-installs \
#     --concurrency-level="$(nproc)" \
#     --install-libglvnd \
#     --systemd \
#     --no-rebuild-initramfs

# sudo rm -vf /usr/lib/modprobe.d/nvidia-installer-disable-nouveau.conf
# echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf

sudo chown "$(id -u):$(id -g)" "$LOG_FILE"
sed -i '/-> Building kernel modules/,/-> done\./{/-> Building kernel modules/b;/-> done\./b;d}' "$LOG_FILE"

if [[ -f "$SCRIPT_DIR/nvidia-uninstall.log" ]]; then
    sudo chown "$(id -u):$(id -g)" "$SCRIPT_DIR/nvidia-uninstall.log"
    mv "$SCRIPT_DIR/nvidia-uninstall.log" "$SCRIPT_DIR/nvidia-uninstall-${DRIVER_VERSION%%.*}.log"
fi
