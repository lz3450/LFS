#!/bin/bash

pkgs=(
    libbz2-dev
    libedit-dev
    libffi-dev
    libgdbm-compat-dev
    libgdbm-dev
    libncurses-dev
    libsqlite3-dev
    tcl-dev
    tk-dev
)

sudo apt-get update
sudo apt-get install --no-install-recommends -y "${pkgs[@]}"
