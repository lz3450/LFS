#!/usr/bin/bash
#
# pkglist.sh
#

### constants & variables

## basic development tools
# command: sudo chrootbuild -b -r kzl --no-clean --no-check -s 0 -i
# if stage0 build fails, try to build makedepends first
kzl_stage0_pkgs=(
    ################################
    # base-devel
    ################################
    make
    pkgconf
    autoconf
    automake
    texinfo
    diffutils
    bison
    flex
    patch
    bc
    cmake
)

## toolchain
# command: sudo chrootbuild -b -r kzl --no-clean --no-check -s 1 -i
kzl_stage1_pkgs=(
    ################################
    # pacman
    ################################
    pacman
    pacman-contrib

    ################################
    # initial toolchain
    ################################
    linux-api-headers
    glibc
    binutils
    gcc

    ################################
    # full toolchain
    ################################
    ################
    # binutils
    ################
    jansson
    zlib
    lz4 xz zstd
    binutils

    ################
    # gcc
    ################
    gmp isl mpfr mpc gcc

    ################
    # glibc
    ################
    tzdata glibc
)

kzl_stage2_pkgs=(
)

_kzl_stage2_pkgs=(
    ################################
    # base
    ################################

    ################
    # filesystem
    ################
    iana-etc filesystem

    ################
    # bash
    ################
    ncurses readline bash-completion bash

    ################
    # perl
    ################
    libxcrypt gdbm perl

    ################
    # ca-certificates & openssl
    ################
    libtasn1 libffi p11-kit ca-certificates
    openssl

    ################
    # shadow
    ################
    pcre2 swig libcap-ng audit
    # pam-config pam
    # shadow

    ################
    # gettext
    ################
    # libunistring icu libxml2 gettext

    # ################
    # # python
    # ################
    # expat
    # e2fsprogs keyutils libedit lmdb cyrus-sasl openldap krb5 libtirpc libnsl
    # tcl sqlite
    # elfutils gdb valgrind
    # python

    # ################
    # # compression utils
    # ################
    # bzip2
    # less gzip
    # xz
    # attr acl tar

    # ################
    # # utils
    # ################
    # grep
    # sed
    # libsigsegv gawk
    # libseccomp file
    # findutils
    # which

    # ################
    # # coreutils
    # ################
    # libcap coreutils

    # ################
    # # curl
    # ################
    # brotli
    # libidn2
    # nghttp2
    # libgpg-error libgcrypt libxslt libpsl
    # libssh2
    # curl

    # ################
    # # llvm
    # ################
    # llvm-project

    # ################
    # # rust
    # ################
    # rust

    # ################
    # # util-linux
    # ################
    # thin-provisioning-tools argon2 libaio device-mapper json-c popt cryptsetup
    # util-linux

    # ################
    # # iptables
    # ################
    # libmnl libnfnetlink libnetfilter_conntrack
    # libnftnl
    # dbus libnl libpcap
    # iptables

    # ################
    # # systemd
    # ################
    # kbd
    # kmod
    # lz4
    # kexec-tools
    # nettle gnutls libmicrohttpd
    # gperf
    # rpcsvc-proto quota
    # systemd
    # util-linux dbus systemd

    # ################
    # # wget
    # ################
    # lzip
    # wget2

    # ################
    # # sudo
    # ################
    # sudo

    # ################
    # # pacman
    # ################
    # fakeroot
    # libassuan libksba npth pinentry gnupg gpgme
    # libarchive
    # pacman
    # pacman-contrib
    # arch-install-scripts

    # ################
    # # ps utils
    # ################
    # procps-ng
    # psmisc

    # ################
    # # ip utils
    # ################
    # iputils
    # iproute2

    # ################
    # # pciutils
    # ################
    # hwdata
    # pciutils

    # ################
    # # usbutils
    # ################
    # libusb
    # usbutils

    # ################
    # # cmake
    # ################
    # jsoncpp
    # libuv
    # rhash
    # cmake

    # ################
    # # man-db
    # ################
    # groff libpipeline
    # man-db

    # ################
    # # base
    # ################
    # base

    # ################
    # # linux-firmware
    # ################
    # linux-firmware
    # pahole
)

kzl_stage3_pkgs=(
    ################
    # shells
    ################
    pcre zsh
    fish

    ################
    # utils
    ################
    openssh
    nano
    git

    ################
    # File system utils
    ################
    dosfstools
    f2fs-tools
    parted

    ################
    # dpkg
    ################
    libmd dpkg
    debootstrap

    ################
    # iso
    ################
    cpio dracut
    libburn libisofs libisoburn
    mtools

    ################
    # Wireless Network
    ################
    iw wpa_supplicant
    wireless-regdb

    ################
    # samba
    ################
    liburing
    samba

    ################
    # rsync
    ################
    xxhash
    rsync

    ################
    # tmux
    ################
    libevent tmux

    ################
    # texlive
    ################
    libpng
    glib2 shared-mime-info
    fontconfig freetype2 lzo pixman cairo
    graphite
    gobject-introspection
    harfbuzz freetype2
    libpaper
    nasm libjpeg-turbo
    libtiff lcms2 openjpeg
    ghostscript
    gd
    zziplib
    texlive

    ################
    # node
    ################
    # c-ares
    # node

    ################
    # other libraries
    ################
    openblas
    libpciaccess hwloc openmpi boost
    ################
    # other utils
    ################
    # tree
    # minicom
    # dfu-util
    # smartmontools
    aria2
    # libtorrent-rasterbar qbittorrent
)

ubuntu_pkgs=(
    pacman
    pacman-contrib
    arch-install-scripts
    # linux
    debootstrap
)
