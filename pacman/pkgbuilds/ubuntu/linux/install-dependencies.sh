#!/bin/bash

sudo apt-get update
sudo apt-get install --no-install-recommends -y \
    bc \
    bison \
    flex \
    libelf-dev \
    libncurses-dev \
    libssl-dev \
    pahole \
    rsync
