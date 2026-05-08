#!/usr/bin/env bash
#
# 10-config-rdp.sh
#

set -e

if (( EUID < 1000 )); then
    echo "This script should be run as user"
    exit 255
fi

. /etc/os-release

CERT_DIR="$HOME"/.local/share/gnome-remote-desktop/certificates
KEY="$CERT_DIR"/rdp-tls.key
CSR="$CERT_DIR"/rdp-tls.csr
CRT="$CERT_DIR"/rdp-tls.crt

if [[ $UBUNTU_CODENAME == "noble" ]]; then
    sudo systemctl disable --now gnome-remote-desktop.service
fi
sudo nano /etc/gdm3/custom.conf
systemctl --user enable --now gnome-remote-desktop-headless.service

if [[ ! -d  "$CERT_DIR" ]]; then
    mkdir -p "$CERT_DIR"
    openssl genrsa -out "$KEY" 4096
    openssl req -new -key "$KEY" -out "$CSR"
    openssl x509 -req -days 365 -signkey "$KEY" -in "$CSR" -out "$CRT"
fi

grdctl rdp set-tls-cert "$CRT"
grdctl rdp set-tls-key "$KEY"
grdctl rdp enable
grdctl rdp disable-view-only

./unlock_remote_desktop.sh
read -r -p "Enter rdp username: " username
echo
read -r -s -p "Enter rdp password: " password
echo
grdctl rdp set-credentials "$username" "$password"
grdctl status --show-credentials

echo "Successfully initialized RDP service"
