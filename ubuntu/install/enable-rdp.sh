#!/bin/bash
#
# enable-rdp.sh
#

set -e

CERT_DIR=$HOME/.local/share/gnome-remote-desktop/certificate
KEY="$CERT_DIR"/grd-tls.key
CSR="$CERT_DIR"/grd-tls.csr
CRT="$CERT_DIR"/grd-tls.crt

if [[ ! -d  "$CERT_DIR" ]]; then
    mkdir -p "$CERT_DIR"
    openssl genrsa -out "$CERT_DIR"/grd-tls.key 4096
    openssl req -new -key "$KEY" -out "$CERT_DIR"/grd-tls.csr
    openssl x509 -req -days 365 -signkey "$KEY" -in "$CSR" -out "$CRT"
fi

grdctl rdp set-tls-cert "$CRT"
grdctl rdp set-tls-key "$KEY"
grdctl rdp enable
grdctl rdp disable-view-only
read -r -s -p "Enter rdp password: " password
grdctl rdp set-credentials kzl "$password"
grdctl status --show-credentials
