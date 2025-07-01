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
for _pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    apt-get purge -y $_pkg
done
unset _pkg

# Add Docker's official GPG key:
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /usr/share/keyrings/docker.asc
chmod a+r /usr/share/keyrings/docker.asc

# Add the repository to Apt sources:
cat > /etc/apt/sources.list.d/docker.sources << EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME:-$VERSION_CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /usr/share/keyrings/docker.asc
EOF

apt-get update
apt-get --no-install-recommends -s install "${pkgs[@]}" | grep "^Inst" | awk '{print $2}' | LC_ALL=C sort -n > "$LOG_DIR/docker_to_install_pkgs.txt"
apt-get --no-install-recommends -y install "${pkgs[@]}"

usermod -aG docker ${SUDO_USER}

chown -R ${SUDO_UID:-0}:${SUDO_GID:-0} -- "$LOG_DIR"
echo "Successfully installed docker for Ubuntu $UBUNTU_CODENAME"
