#!/bin/bash
# 
# update_repo.sh
#

set -exu -o pipefail

REPODIR=/var/repository

core_pkgs=(
    filesystem
    linux-api-headers
    glibc
    gcc
    libtool
    iana-etc
    tzdata
    zlib minizip
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
    libldap # openldap
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
    libunistring
    icu
    libxml2
    gettext
    elfutils
    gc
    libffi
    guile
    make
    libnsl
    mpdecimal
    tcl
    sqlite
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
    lapack
    cython
    python-numpy
    boost
    thin-provisioning-tools
    lvm2 device-mapper
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
    libmicrohttpd
    libpng
    libpwquality
    qrencode
    gperf
    autoconf-archive
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
    pacman-contrib
    git
    which
    sudo
    jsoncpp
    libuv
    rhash
    glib2
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
    dosfstools
    nano
    wpa_supplicant
    parted
    texinfo
    groff
    base
    linux
    linux-firmware
)

extra_pkgs=()

community_pkgs=()

update() {
    local repo
    repo=$1
    local pkg
    pkg=$2

    pkgname=$pkg-[0-9]*.pkg.tar.zst

    if [ -f ~/makepkg/packages/$pkgname ]; then
        sudo mv ~/makepkg/packages/$pkgname $REPODIR/$repo
    fi
    sudo repo-add -R $REPODIR/$repo/$repo.db.tar.zst $REPODIR/$repo/$pkgname
}

repo=$1

if [ ! -d $REPODIR/$repo ]; then
    sudo mkdir -p $REPODIR/$repo
fi

case $repo in
    core)
        pkgs=${core_pkgs[@]}
        ;;
    extra)
        pkgs=${extra_pkgs[@]}
        ;;
    community)
        pkgs=${community_pkgs[@]}
        ;;
    *)
        # unknow repo
        exit 1
        ;;
esac

sudo find $REPODIR/$repo -name "$repo.*" -delete
sudo repo-add $REPODIR/$repo/$repo.db.tar.zst

for p in ${pkgs[@]}; do
    update $repo $p
done
