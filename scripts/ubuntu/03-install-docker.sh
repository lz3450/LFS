#!/bin/bash
#
# 03-install-docker.sh
#

set -e

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 255
fi

. /etc/os-release
LOG_DIR="log/$UBUNTU_CODENAME"

pkgs=(
    docker-ce
    docker-ce-cli
    containerd.io
    docker-buildx-plugin
    docker-compose-plugin
)

apt-get update
apt-get upgrade -y

### Uninstall all conflicting packages
apt-get purge -y $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)

# Add Docker's official GPG key:
apt-get update
apt-get install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
tee /etc/apt/sources.list.d/docker.sources << EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME:-$VERSION_CODENAME}
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt-get update
apt-get --no-install-recommends -s install "${pkgs[@]}" | grep "^Inst" | awk '{print $2}' | LC_ALL=C sort -n > "$LOG_DIR/docker_to_install_pkgs.txt"
apt-get --no-install-recommends -y install "${pkgs[@]}"

usermod -aG docker ${SUDO_USER}

chown -R ${SUDO_UID:-0}:${SUDO_GID:-0} -- "$LOG_DIR"
echo "Successfully installed docker for Ubuntu $UBUNTU_CODENAME"
