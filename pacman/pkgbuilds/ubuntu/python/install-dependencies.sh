#!/bin/bash

. /etc/os-release

pkgs=(
    libbz2-dev
    libedit-dev
    libffi-dev
    libgdbm-compat-dev
    libgdbm-dev
    libncurses-dev
    libsqlite3-dev
    libzstd-dev
    tcl-dev
    tk-dev
)

if [[ "$UBUNTU_CODENAME" == "jammy" ]]; then
    pkgs+=(libmpdec-dev)
fi

sudo apt-get update
sudo apt-get install --no-install-recommends -y "${pkgs[@]}"
