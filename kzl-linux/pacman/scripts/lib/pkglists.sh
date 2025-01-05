#!/usr/bin/bash
#
# pkglist.sh
#

### constants & variables

# preparation
kzl_stage0_pkgs=(
)

# toolchain
kzl_stage1_pkgs=(
    ################################
    # toolchain
    ################################

    ################
    # filesystem
    ################
    iana-etc filesystem

    # ################
    # # glibc
    # ################
    # linux-api-headers
    # tzdata
    # glibc

    # ################
    # # binutils
    # ################
    # jansson
    # zlib
    # zstd
    # binutils

    # ################
    # # gcc
    # ################
    # gmp isl
    # mpfr mpc
    # gcc

    # ################################
    # tzdata glibc
    # jansson zlib zstd bc binutils
    # gmp isl mpfr mpc gcc
    # libtool
)

# base
kzl_stage2_pkgs=(
    ################################
    # base
    ################################

    ################
    # bash
    ################
    ncurses readline bash bash-completion

    ################
    # perl
    ################
    libxcrypt db gdbm perl

    ################
    # texinfo
    ################
    help2man texinfo

    ################################
    # other base-development
    ################################
    m4
    autoconf automake autoconf-archive
    bison
    flex
    ed bc
    diffutils
    patch
    which
    pkgconf

    ################
    # make
    ################
    libffi gc guile
    make

    ################
    # gettext
    ################
    libunistring icu libxml2 gettext

    ################
    # ca-certificates & openssl
    ################
    libtasn1 p11-kit ca-certificates
    openssl

    ################
    # python
    ################
    expat
    e2fsprogs keyutils libedit lmdb cyrus-sasl openldap krb5 libtirpc libnsl
    tcl sqlite
    elfutils gdb valgrind
    python

    ################
    # compression utils
    ################
    bzip2
    pcre2 less gzip
    xz
    attr acl tar

    ################
    # utils
    ################
    grep
    sed
    libsigsegv gawk
    libseccomp file
    findutils

    ################
    # shadow
    ################
    swig libcap-ng audit
    pam-config pam
    shadow

    ################
    # coreutils
    ################
    libcap coreutils

    ################
    # curl
    ################
    brotli
    libidn2
    nghttp2
    libgpg-error libgcrypt libxslt libpsl
    libssh2
    curl

    ################
    # llvm
    ################
    llvm-project

    ################
    # rust
    ################
    rust

    ################
    # util-linux
    ################
    thin-provisioning-tools argon2 libaio device-mapper json-c popt cryptsetup
    util-linux

    ################
    # iptables
    ################
    libmnl libnfnetlink libnetfilter_conntrack
    libnftnl
    dbus libnl libpcap
    iptables

    ################
    # systemd
    ################
    kbd
    kmod
    lz4
    kexec-tools
    nettle gnutls libmicrohttpd
    gperf
    rpcsvc-proto quota
    systemd
    util-linux dbus systemd

    ################
    # wget
    ################
    lzip
    wget2

    ################
    # sudo
    ################
    sudo

    ################
    # pacman
    ################
    fakeroot
    libassuan libksba npth pinentry gnupg gpgme
    libarchive
    pacman
    pacman-contrib
    arch-install-scripts

    ################
    # ps utils
    ################
    procps-ng
    psmisc

    ################
    # ip utils
    ################
    iputils
    iproute2

    ################
    # pciutils
    ################
    hwdata
    pciutils

    ################
    # usbutils
    ################
    libusb
    usbutils

    ################
    # cmake
    ################
    jsoncpp
    libuv
    rhash
    cmake

    ################
    # man-db
    ################
    groff libpipeline
    man-db

    ################
    # base
    ################
    base

    ################
    # linux-firmware
    ################
    linux-firmware
    pahole
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
