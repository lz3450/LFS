#!/usr/bin/bash
#
# pkglist.sh
#

ubuntu_stage1_pkgs=(
    pacman
    llvm-project
    python
    ksmbd-tools
    texlive
)

ubuntu_stage2_pkgs=(
    llvm-project
    rust
    debootstrap
    dracut
)
