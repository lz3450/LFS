#!/bin/bash

pkgs=(
    fontconfig
    ghostscript
    libcairo2-dev
    libfreetype-dev
    libgd-dev
    libgmp-dev
    libgraphite2-dev
    libharfbuzz-dev
    libicu-dev
    # libkpathsea-dev # not working
    # libmpfi-dev # too old
    libmpfr-dev
    libpixman-1-dev
    libpng-dev
    libpotrace-dev
    # libptexenc-dev # `--with-system-ptexenc' requires `--with-system-kpathsea'
    libteckit-dev
    libzzip-dev
    texinfo

)

sudo apt-get install "${pkgs[@]}"
