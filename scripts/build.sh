#!/bin/bash
# 
# build.sh
#

set -exu -o pipefail

PKGDEST=/var/makepkg
scriptdir=$(pwd)

stage1_pkgs=(
    linux-api-headers
    glibc
    binutils
    gcc
    libtool
)

stage2_pkgs=(
    binutils
    glibc
)

core_pkgs=(
    linux-api-headers
    glibc
    gcc
    libtool
    iana-etc
    tzdata
    zlib
    bzip2
    xz
    file
    readline
    m4
    ed
    bc
    binutils
    gmp
    mpfr
    mpc
    attr
    acl
    cracklib
    keyutils
    openssl
    libsasl
    openldap # libldap
    krb5
    libtirpc
    pam
    libcap-ng
    pcre
    swig
    audit
    shadow
    pkgconf
    ncurses
    libcap
    sed
    psmisc
    bison
    flex
    grep
    bash
    db
    gdbm
    expat
    perl
    diffutils
    autoconf
    automake
    kmod
    gettext
    elfutils
    libffi
    make
    libnsl
    mpdecimal
    tcl
    sqlite
    gc
    libunistring
    guile
    gdb
    valgrind
    python
    ninja
    meson
    coreutils
    gawk
    findutils
    less
    gzip
    zstd
    libmnl
    libnfnetlink
    libnetfilter_conntrack
    libnftnl
    libnl
    libusb
    libpcap
    iptables
    iproute2
    patch
    tar
    argon2
    libaio
    icu
    lapack
    cython
    python-numpy
    boost
    thin-provisioning-tools
    lvm2 #device-mapper
    json-c
    libgpg-error
    libgcrypt
    popt
    cryptsetup
    ca-certificates
    libidn2
    libnghttp2
    publicsuffix-list
    libpsl
    libssh2
    curl
    gnu-efi
    iptables
    check
    kbd
    libseccomp
    lz4
    libtasn1
    p11-kit
    pcre2
    libpng
    libpwquality
    qrencode
    gperf
    dbus
    systemd
    procps-ng
    util-linux
    e2fsprogs
    nettle
    gnutls
    libassuan
    libksba
    npth
    libusb-compat
    pcsclite
    gnupg
    swig
    gpgme
    libarchive
    pacman
    git
    which
    sudo
    jsoncpp
    libuv
    rhash
    glib2
    libxml2
    itstool
    shared-mime-info
    cmake
    libedit
    libxslt
    iputils
    pciutils
    hidapi
    libcbor
    libfido2
    openssh
    rsync
    fakeroot
    arch-install-scripts
    base
)

build() {
    local pkg
    pkg=$1

    cd "$scriptdir"/../$repo/$pkg

    local log
    log=$pkg.log
    if [[ -f $log ]]; then
        rm $log
    fi

    # gpg --recv-keys $(grep -E -o "[0-9A-F]{40}" PKGBUILD)
    # updpkgsums
    makepkg -scCLf --skippgpcheck --nocheck --noconfirm &>> $log
}

case $1 in
    core)
        pkgs=${core_pkgs[@]}
        repo='core'
        ;;
    *)
        # unknow repo
        exit 1
        ;;
esac

for p in ${pkgs[@]}; do
    build $p
done