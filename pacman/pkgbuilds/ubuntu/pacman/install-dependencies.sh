#!/bin/bash

sudo apt-get update
sudo apt-get install --no-install-recommends -y \
    bash-completion \
    cmake \
    fakechroot \
    fakeroot \
    file \
    libarchive-dev \
    libarchive-tools \
    libcurl4-openssl-dev \
    libgpgme-dev \
    libssl-dev \
    pkg-config \
    zstd
