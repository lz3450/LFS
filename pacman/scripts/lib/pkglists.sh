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
    # base-devel (GNU tools)
    ################################
    make
    pkgconf
    m4 autoconf
    automake
    texinfo
    diffutils
    bison
    libtool help2man flex
    ed patch
    bc
)

## toolchain
# command: sudo chrootbuild -b -r kzl --no-clean --no-check -s 1 -i
kzl_stage1_pkgs=(
    ################################
    # pacman
    ################################
    pacman

    ################################
    # initial toolchain
    ################################
    linux-api-headers
    glibc
    binutils
    gcc
    glibc
    binutils
    gcc
)

kzl_stage2_pkgs=(
    ################################
    # full toolchain
    ################################
    ################
    # glibc
    ################
    tzdata glibc

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

    ################################
    # bash
    ################################
    ncurses
    readline
    bash-completion
    bash

    ################################
    # base-devel (GNU tools)
    ################################
    "${kzl_stage0_pkgs[@]}"

    ################################
    # ca-certificates
    ################################
    libffi libtasn1 p11-kit
    ca-certificates

    ################################
    # base-devel (git, cmake)
    ################################
    ################
    # curl
    ################
    libunistring libidn2
    libpsl
    openssl libssh2
    nghttp2
    curl

    expat pcre2 git

    ################
    # libarchive
    ################
    attr acl
    bzip2
    icu libxml2
    libarchive

    libuv rhash jsoncpp cmake

    ################################
    # gettext
    ################################
    gettext

    ################################
    # filesystem
    ################################
    iana-etc filesystem

    ################################
    # shadow
    ################################
    ################
    # audit
    ################
    swig libcap-ng
    audit

    ################
    # pam
    ################
    gdbm
    libxcrypt
    pam-config
    pam

    shadow

    ################################
    # pacman
    ################################
    fakeroot
    # libgpg-error libassuan libksba npth pinentry gnupg gpgme
    # pacman

    ################################
    # perl
    ################################
    # perl

    # ################
    # # python
    # ################
    # e2fsprogs keyutils libedit lmdb cyrus-sasl openldap krb5 libnsl
    # tcl sqlite
    # elfutils gdb valgrind
    # python

    # ################
    # # compression utils
    # ################
    # less gzip
    # xz
    # tar

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
    # kexec-tools
    # nettle gnutls libmicrohttpd
    # gperf
    # rpcsvc-proto quota
    # systemd
    # util-linux dbus systemd
    # p11-kit

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

jammy_stage1_pkgs=(
    pacman
    llvm-project
    python
    ksmbd-tools
    texlive
    debootstrap
    dracut
    erofs-utils
    kexec-tools
)

jammy_stage2_pkgs=(
    llvm-project
    rust
)

noble_stage1_pkgs=(
    pacman
    debootstrap
    dracut
    erofs-utils
    kexec-tools
)
