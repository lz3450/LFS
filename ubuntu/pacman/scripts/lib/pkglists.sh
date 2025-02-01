#!/usr/bin/bash
#
# pkglist.sh
#

ubuntu_stage1_pkgs=(
    pacman
    ksmbd-tools
    kexec-tools
    python
    debootstrap
    dracut
    texlive
    llvm-project
)

ubuntu_stage2_pkgs=(
    llvm-project
    rust
)
