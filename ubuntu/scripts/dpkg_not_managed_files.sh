#!/bin/bash

# SCRIPT='
#     for file do
#         if ! dpkg -S "$file" &>/dev/null; then
#         echo "$file"
#         fi
#     done
# '

# SCRIPT='
#     for file do
#         if ! dpkg -S "$file" &>/dev/null && ! dpkg -S "${file/\/usr\//}" &>/dev/null; then
#             echo "$file"
#         fi
#     done
# '

# -exec bash -c "$SCRIPT" {} +

dpkg_managed_files="/tmp/dpkg_managed_files.txt"

dpkg -L $(dpkg-query -f '${binary:Package}\n' -W) 2>/dev/null | sort -u > $dpkg_managed_files

### /boot
find /boot \
    -type d \( \
        -path /boot/efi -o \
        -path /boot/grub \
    \) -prune -o \
    -type f ! \( \
        -name update-kernel.sh -o \
        -name 'vmlinuz-*-KZL' -o \
        -name 'initrd.img-*-KZL' -o \
        -name 'initrd.img-*-generic' \
    \) \
    -print | sort -u > /tmp/found_files.txt
comm -23 /tmp/found_files.txt $dpkg_managed_files | xargs realpath 2>/dev/null


### /etc
find /etc \
    -type d \( \
        -path /etc/ssl/certs -o \
        -path /etc/pam.d -o \
        -path /etc/samba -o \
        -path /etc/ssh -o \
        -path /etc/xml -o \
        -path /etc/ros -o \
        -path /etc/X11 \
    \) -prune -o \
    -type f ! \( \
        -name passwd -o \
        -name passwd- -o \
        -name group- -o \
        -name shadow -o \
        -name shadow- -o \
        -name gshadow -o \
        -name gshadow- -o \
        -name 'subuid' -o \
        -name 'subuid-' -o \
        -name 'subgid' -o \
        -name 'subgid-' -o \
        -name timezone -o \
        -name machine-id -o \
        -name shells -o \
        -name hostname -o \
        -wholename /etc/profile.d/texlive.sh -o \
        -name ld.so.cache \
    \) \
    -print | sort -u > /tmp/found_files.txt
comm -23 /tmp/found_files.txt $dpkg_managed_files | xargs realpath 2>/dev/null


### /usr/share
find /usr/share \
    -type d \( \
        -path '**/__pycache__' -o \
        -path /usr/share/fonts -o \
        -path /usr/share/mime -o \
        -path /usr/share/icons -o \
        -path /usr/share/egl -o \
        -path /usr/share/glvnd -o \
        -path /usr/share/vim -o \
        -path /usr/share/keyrings -o \
        -path /usr/share/doc/NVIDIA_GLX-1.0 \
    \) -prune -o \
    -type f ! \( \
        -name .uuid -o \
        -name 'nvidia-*' -o \
        -name '*.desktop' -o \
        -name '*.compiled' -o \
        -name '*.cache' \
    \) \
    -print | sort -u > /tmp/found_files.txt
comm -23 /tmp/found_files.txt $dpkg_managed_files | xargs realpath 2>/dev/null

### /usr/libexec
find /usr/libexec \
    -type d -o \
    -type f \
    -print | sort -u > /tmp/found_files.txt
comm -23 /tmp/found_files.txt $dpkg_managed_files | xargs realpath 2>/dev/null

### /var
find /var \
    -type d \( \
        -path /var/backups -o \
        -path /var/crash -o \
        -path /var/lib -o \
        -path /var/cache -o \
        -path /var/log -o \
        -path /var/spool \
    \) -prune -o \
    -type f \
    -print | sort -u > /tmp/found_files.txt
comm -23 /tmp/found_files.txt $dpkg_managed_files | xargs realpath 2>/dev/null

### /usr/lib /usr/bin /usr/sbin
dpkg -L $(dpkg-query -f '${binary:Package}\n' -W) 2>/dev/null | sed 's/^\/usr//' | sort -u > $dpkg_managed_files

### /usr/lib
find /usr/lib \
    -type d \( \
        -path '**/__pycache__' -o \
        -path /usr/lib/cups/backend -o \
        -path /usr/lib/nvidia -o \
        -path /usr/lib/firmware/nvidia -o \
        -path /usr/lib/x86_64-linux-gnu/nvidia/wine -o \
        -path /usr/lib/modules \
    \) -prune -o \
    -type f ! \( \
        -wholename /usr/lib/locale/locale-archive -o \
        -wholename '/usr/lib/systemd/system/system-systemd\\x2dcryptsetup.slice' -o \
        -wholename /usr/lib/udev/hwdb.bin -o \
        -wholename /usr/lib/systemd/system-sleep/nvidia -o \
        -wholename /usr/lib/xorg/modules/drivers/nvidia_drv.so -o \
        -wholename /usr/lib/modprobe.d/nvidia-installer-disable-nouveau.conf -o \
        -wholename /usr/lib/pkgconfig/accinj64-12.1.pc -o \
        -wholename /usr/lib/pkgconfig/cublas-12.pc -o \
        -wholename /usr/lib/pkgconfig/cuda-12.1.pc -o \
        -wholename /usr/lib/pkgconfig/cudart-12.1.pc -o \
        -wholename /usr/lib/pkgconfig/cufft-11.0.pc -o \
        -wholename /usr/lib/pkgconfig/cufftw-11.0.pc -o \
        -wholename /usr/lib/pkgconfig/cufile-1.6.pc -o \
        -wholename /usr/lib/pkgconfig/cuinj64-12.1.pc -o \
        -wholename /usr/lib/pkgconfig/curand-10.3.pc -o \
        -wholename /usr/lib/pkgconfig/cusolver-11.4.pc -o \
        -wholename /usr/lib/pkgconfig/cusparse-12.0.pc -o \
        -wholename /usr/lib/pkgconfig/nppc-12.0.pc -o \
        -wholename /usr/lib/pkgconfig/nppi-12.0.pc -o \
        -wholename /usr/lib/pkgconfig/nppial-12.0.pc -o \
        -wholename /usr/lib/pkgconfig/nppicc-12.0.pc -o \
        -wholename /usr/lib/pkgconfig/nppicom-12.0.pc -o \
        -wholename /usr/lib/pkgconfig/nppidei-12.0.pc -o \
        -wholename /usr/lib/pkgconfig/nppif-12.0.pc -o \
        -wholename /usr/lib/pkgconfig/nppig-12.0.pc -o \
        -wholename /usr/lib/pkgconfig/nppim-12.0.pc -o \
        -wholename /usr/lib/pkgconfig/nppist-12.0.pc -o \
        -wholename /usr/lib/pkgconfig/nppisu-12.0.pc -o \
        -wholename /usr/lib/pkgconfig/nppitc-12.0.pc -o \
        -wholename /usr/lib/pkgconfig/npps-12.0.pc -o \
        -wholename /usr/lib/pkgconfig/nvidia-ml-12.1.pc -o \
        -wholename /usr/lib/pkgconfig/nvjitlink-12.1.pc -o \
        -wholename /usr/lib/pkgconfig/nvjpeg-12.1.pc -o \
        -wholename /usr/lib/pkgconfig/nvrtc-12.1.pc -o \
        -wholename /usr/lib/pkgconfig/nvToolsExt-12.1.pc -o \
        -wholename /usr/lib/pkgconfig/opencl-12.1.pc -o \
        -name 'libnvcuvid.so*' -o \
        -name 'libnvoptix.so*' -o \
        -name 'nvidia-*.service' -o \
        -name 'libnvidia-*.so*' -o \
        -name 'libcuda*.so*' -o \
        -name 'lib*nvidia.so*' -o \
        -name '*.cache' \
    \) \
    -type l \
    -print | sed 's/^\/usr//' | sort -u > /tmp/found_files.txt
comm -23 /tmp/found_files.txt $dpkg_managed_files | xargs realpath 2>/dev/null

## /usr/lib64
find /usr/lib64 \
    -type d \( \
        -path '**/__pycache__' \
    \) -prune -o \
    -type f ! \( \
        -name '*.cache' \
    \) \
    -type l \
    -print | sed 's/^\/usr//' | sort -u > /tmp/found_files.txt
comm -23 /tmp/found_files.txt $dpkg_managed_files | xargs realpath 2>/dev/null

### /usr/bin
find /usr/bin \
    -type d \
    -o \
    -type f ! \( \
        -name 'nvidia-*' \
    \) \
    -print | sed 's/^\/usr//' | sort -u > /tmp/found_files.txt
comm -23 /tmp/found_files.txt $dpkg_managed_files | xargs realpath 2>/dev/null

### /usr/sbin
find /usr/sbin \
    -type d \
    -o \
    -type f ! \( \
        -name 'nvidia-*' \
    \) \
    -print | sed 's/^\/usr//' | sort -u > /tmp/found_files.txt
comm -23 /tmp/found_files.txt $dpkg_managed_files | xargs realpath 2>/dev/null
