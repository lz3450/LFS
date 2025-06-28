#!/bin/bash

sudo apt-get update
sudo apt-get install --no-install-recommends -y \
    cmake \
    libedit-dev \
    libffi-dev \
    liblzma-dev \
    libxml2-dev \
    libzstd-dev \
    zlib1g-dev
