#!/bin/bash

SCRIPT='
    for file do
        if ! dpkg -S "$file" &>/dev/null; then
        echo "$file"
        fi
    done
'

# find /boot \
#     -type d \( \
#         -path /boot/efi -o \
#         -path /boot/grub \
#     \) -prune -o \
#     -type f \
#     ! \( \
#         -name vmlinuz-*-KZL -o \
#         -name initrd.img-*-KZL -o \
#         -name initrd.img-*-generic \
#     \) \
#     -exec bash -c "$SCRIPT" {} +


# find /etc \
#     -type d \( \
#         -path /etc/samba -o \
#         -path /etc/ssh -o \
#         -path /etc/ros -o \
#         -path /etc/X11 \
#     \) -prune -o \
#     -type f \
#     ! \( \
#         -name passwd- -o \
#         -name group- -o \
#         -name shadow -o \
#         -name shadow- -o \
#         -name gshadow -o \
#         -name gshadow- -o \
#         -name subuid-- -o \
#         -name subgid-- -o \
#         -name timezone -o \
#         -name machine-id -o \
#         -name shells -o \
#         -name hostname -o \
#         -wholename /etc/profile.d/texlive.sh -o \
#         -name ld.so.cache \
#     \) \
#     -exec bash -c "$SCRIPT" {} +


SCRIPT='
    for file do
        if ! dpkg -S "$file" &>/dev/null && ! dpkg -S "/usr$file" &>/dev/null; then
        echo "$file"
        fi
    done
'

find -L /lib \
    -type f \
    ! \( \
        -wholename /lib/systemd/system-sleep/nvidia -o \
        -wholename /lib/udev/hwdb.bin -o \
        -wholename /lib/x86_64-linux-gnu/gio/modules/giomodule.cache \
    \) \
    -exec bash -c "$SCRIPT" {} +