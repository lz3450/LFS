#!/bin/bash
# 
# build_all.sh
#

set -exu -o pipefail

scriptdir=$(pwd)

tools_stage1_pkgs=(
    linux-api-headers
)

core_pkgs=(
    acl
    argon2
    attr
    audit
    autoconf
    automake
    base
    bash
    bc
    binutils
    bison
    boost
    bzip2
    ca-certificates
    cmake
    coreutils
    cracklib
    cryptsetup
    curl
    cython
    db
    dbus
    diffutils
    e2fsprogs
    ed
    elfutils
    expat
    fakeroot
    file
    findutils
    flex
    gawk
    gc
    gcc
    gdb
    gdbm
    gettext
    git
    glib2
    glibc
    gmp
    gnupg
    gnutls
    gnu-efi
    gperf
    gpgme
    grep
    guile
    gzip
    hidapi
    iana-etc
    icu
    iproute2
    iptables
    iputils
    itstool
    jsoncpp
    json-c
    kbd
    keyutils
    kmod
    krb5
    lapack
    less
    libaio
    libarchive
    libassuan
    libcap
    libcap-ng
    libcbor
    libedit
    libffi
    libfido2
    libgcrypt
    libgpg-error
    libidn2
    libksba
    libmicrohttpd
    libmnl
    libnetfilter_conntrack
    libnfnetlink
    libnftnl
    libnghttp2
    libnl
    libnsl
    libpcap
    libpng
    libpsl
    libsasl
    libseccomp
    libssh2
    libtasn1
    libtirpc
    libtool
    libunistring
    libusb
    libusb-compat
    libuv
    libxml2
    lvm2
    lz4
    m4
    make
    meson
    mpc
    mpfr
    nano
    ncurses
    nettle
    ninja
    npth
    nss
    openldap
    openssh
    openssl
    p11-kit
    pacman
    pam
    patch
    pciutils
    pcre
    pcre2
    pcsclite
    perl
    pkgconf
    popt
    procps-ng
    psmisc
    publicsuffix-list
    python
    python-numpy
    qrencode
    readline
    rhash
    sed
    shadow
    shared-mime-info
    sqlite
    sudo
    swig
    systemd
    tar
    tcl
    thin-provisioning-tools
    tzdata
    util-linux
    valgrind
    which
    xz
    zlib
    zstd
)

build() {
    cd "$scriptdir"/../$1/$2
    log=$2.log
    if [[ -f $log ]]; then
        rm $log
    fi
    gpg --recv-keys $(grep -E -o "[0-9A-F]{40}" PKGBUILD)
    # updpkgsums
    makepkg --config "$scriptdir"/../config/makepkg-lfs.conf -scCLf --nocheck --noconfirm &>> $log
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
    build $repo $p
done
