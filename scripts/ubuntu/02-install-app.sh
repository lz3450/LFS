#!/bin/bash
#
# 02-install-app.sh
#

set -e

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 255
fi

. /etc/os-release
LOG_DIR="log/$UBUNTU_CODENAME"
ARCH=$(dpkg --print-architecture)

### utils
utils_deb_pkgs=(
    landscape-client
    tmux
    # screen
)

apt-get update
apt-get upgrade -y
apt-get install --no-install-recommends -s "${utils_deb_pkgs[@]}" | grep "^Inst" | awk '{print $2}' | LC_ALL=C sort -n > "$LOG_DIR/utils_to_install_pkgs.txt"
apt-get install --no-install-recommends -y "${utils_deb_pkgs[@]}"
dpkg --get-selections | awk '{print $1}' | sed -e 's/:amd64//g' -e 's/:arm64//g' > "$LOG_DIR/utils_installed_pkgs.txt"

### microsoft
microsoft_deb_pkgs=(
    code
)

cat > /etc/apt/sources.list.d/vscode.sources << EOF
Types: deb
URIs: https://packages.microsoft.com/repos/code/
Suites: stable
Components: main
Architectures: $ARCH
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF
if [[ "$ARCH" == "amd64" ]]; then
    microsoft_deb_pkgs+=(microsoft-edge-stable)
    cat > /etc/apt/sources.list.d/microsoft-edge.sources << EOF
Types: deb
URIs: https://packages.microsoft.com/repos/edge/
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF
fi

curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | install -o root -g root -m 644 /dev/stdin /usr/share/keyrings/microsoft.gpg

apt-get update
apt-get install --no-install-recommends -s "${microsoft_deb_pkgs[@]}" | grep "^Inst" | awk '{print $2}' | LC_ALL=C sort -n > "$LOG_DIR/microsoft_to_install_pkgs.txt"
apt-get install --no-install-recommends -y "${microsoft_deb_pkgs[@]}"
dpkg --get-selections | awk '{print $1}' | sed -e 's/:amd64//g' -e 's/:arm64//g' > "$LOG_DIR/microsoft_installed_pkgs.txt"
rm -vf -- /etc/apt/sources.list.d/microsoft-edge.list

chown -R ${SUDO_UID:-0}:${SUDO_GID:-0} -- "$LOG_DIR"
echo "Successfully installed utils and applications for Ubuntu $UBUNTU_CODENAME"
