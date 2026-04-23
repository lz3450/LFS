#!/usr/bin/env bash
#
# 10-config-rdp-system.sh
#

set -e

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 255
fi

. /etc/os-release

CERT_DIR=/var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates
KEY="$CERT_DIR"/rdp-tls.key
CSR="$CERT_DIR"/rdp-tls.csr
CRT="$CERT_DIR"/rdp-tls.crt

systemctl enable --now gnome-remote-desktop.service

if [[ ! -d  "$CERT_DIR" ]]; then
    mkdir -p "$CERT_DIR"
    openssl genrsa -out "$KEY" 4096
    openssl req -new -key "$KEY" -out "$CSR"
    openssl x509 -req -days 365 -signkey "$KEY" -in "$CSR" -out "$CRT"
    chown -R gnome-remote-desktop:gnome-remote-desktop "$CERT_DIR"
fi

grdctl --system rdp set-tls-cert "$CRT"
grdctl --system rdp set-tls-key "$KEY"
grdctl --system rdp enable
grdctl --system rdp disable-view-only
grdctl --system rdp set-port 3389
grdctl --system status --show-credentials

echo "Successfully initialized system RDP service"
