#!/usr/bin/bash
#
# dpkg-not-managed-files.sh
#
# code name: noble
#

DPKG_MANAGED_FILES="/tmp/managed_files.txt"
DPKG_NOT_MANAGED_FILES="/tmp/not_managed_files.txt"

################################################################################

dpkg -L $(dpkg --get-selections | awk '{print $1}') \
    | sed \
        -e '/^$/d' \
        -e '/^\/\./d' \
        -e '/^\//!d' \
        -e 's|^/lib/|/usr/lib/|g' \
        -e 's|^/lib64/|/usr/lib64/|g' \
        -e 's|^/bin/|/usr/bin/|g' \
        -e 's|^/sbin/|/usr/sbin/|g' \
    > "$DPKG_MANAGED_FILES"
pacman -Ql | awk '{print $2}' >> "$DPKG_MANAGED_FILES"
LC_ALL=C sort -u -o "$DPKG_MANAGED_FILES" "$DPKG_MANAGED_FILES"

if [[ -f "$DPKG_NOT_MANAGED_FILES" ]]; then
    rm -vf "$DPKG_NOT_MANAGED_FILES"
fi

### template
# find /path \
#     \( -type d \( \
#         -path /path/to/exclude -o \
#         -path /path/to/exclude \
#     \) -prune \) -o \
#     \( -type f -o -type l \) ! \( \
#         -name /path/to/exclude -o \
#         -wholename /path/to/exclude \
#     \) \
#     -print \
#     | LC_ALL=C sort -u > /tmp/found_files.txt
# LC_ALL=C comm -23 /tmp/found_files.txt "$DPKG_MANAGED_FILES" >> "$DPKG_NOT_MANAGED_FILES"

### /etc
sudo find /etc \
    \( -type d \( \
        -path /etc/ssl/certs -o \
        -path /etc/pam.d \
    \) -prune \) -o \
    \( -type f -o -type l \) ! \( \
        -wholename /etc/group -o \
        -wholename /etc/group- -o \
        -wholename /etc/gshadow -o \
        -wholename /etc/gshadow- -o \
        -wholename /etc/hostname -o \
        -wholename /etc/hosts -o \
        -wholename /etc/subgid -o \
        -wholename /etc/subgid- -o \
        -wholename /etc/subuid -o \
        -wholename /etc/subuid- -o \
        -wholename /etc/shadow -o \
        -wholename /etc/shadow- -o \
        -wholename /etc/shells -o \
        -wholename /etc/locale.conf -o \
        -wholename /etc/locale.gen -o \
        -wholename /etc/machine-id -o \
        -wholename /etc/ld.so.cache -o \
        -wholename /etc/udev/hwdb.bin -o \
        -wholename /etc/profile.d/texlive.sh -o \
        -wholename '/etc/ssh/ssh_host_*' \
    \) \
    -print \
    | LC_ALL=C sort -u > /tmp/found_files.txt
LC_ALL=C comm -23 /tmp/found_files.txt "$DPKG_MANAGED_FILES" >> "$DPKG_NOT_MANAGED_FILES"

### /usr/lib
find /usr/lib \
    \( -type d \( \
        -path '*/__pycache__' \
    \) -prune \) -o \
    \( -type f -o -type l \) ! \( \
        -wholename /usr/lib/udev/hwdb.bin \
    \) \
    -print \
    | LC_ALL=C sort -u > /tmp/found_files.txt
LC_ALL=C comm -23 /tmp/found_files.txt "$DPKG_MANAGED_FILES" >> "$DPKG_NOT_MANAGED_FILES"

### /usr/bin
find /usr/bin \
    -print \
    | LC_ALL=C sort -u > /tmp/found_files.txt
LC_ALL=C comm -23 /tmp/found_files.txt "$DPKG_MANAGED_FILES" >> "$DPKG_NOT_MANAGED_FILES"

### /usr/share
find /usr/share \
    \( -type d \( \
        -path /usr/share/mime -o \
        -path /usr/share/man -o \
        -path /usr/share/icons -o \
        -path '*/__pycache__' \
    \) -prune \) -o \
    \( -type f -o -type l \) \
    -print \
    | LC_ALL=C sort -u > /tmp/found_files.txt
LC_ALL=C comm -23 /tmp/found_files.txt "$DPKG_MANAGED_FILES" >> "$DPKG_NOT_MANAGED_FILES"

### /var
sudo find /var \
    \( -type d \( \
        -path /var/lib/apt -o \
        -path /var/lib/dpkg -o \
        -path /var/lib/pacman -o \
        -path /var/lib/docker -o \
        -path /var/cache -o \
        -path /var/tmp -o \
        -path /var/log \
    \) -prune \) -o \
    \( -type f -o -type l \) ! \( \
        -wholename /var/spool/mail \
    \) \
    -print \
    | LC_ALL=C sort -u > /tmp/found_files.txt
LC_ALL=C comm -23 /tmp/found_files.txt "$DPKG_MANAGED_FILES" >> "$DPKG_NOT_MANAGED_FILES"
