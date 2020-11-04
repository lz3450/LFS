#!/bin/bash

set -e

# ROOTDIR=/dev/shm
# PYTHONVER=3.9.0

PYTHONBIN=/usr/local/bin/python3.9
PIPBIN=/usr/local/bin/pip3.9

# sudo apt update
# sudo apt install -y libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev valgrind liblzma-dev libgdbm-compat-dev libjpeg-dev libffi-dev libmpdec-dev

# cd $ROOTDIR

# if [ -d cpython ]; then
#     sudo rm -rf cpython
# fi
# git clone https://github.com/python/cpython.git -b v$PYTHONVER

# cd cpython
# ./configure \
#     --prefix=/usr/local \
#     --enable-shared \
#     --enable-optimizations \
#     --enable-loadable-sqlite-extensions \
#     --enable-ipv6 \
#     --enable-big-digits \
#     --with-lto \
#     --with-valgrind \
#     --with-computed-gotos \
#     --with-ensurepip

# make -j$(nproc)
# sudo make install
# sudo ln -sf python${PYTHONVER:0:3} /usr/local/bin/python
# sudo ln -sf pip${PYTHONVER:0:3} /usr/local/bin/pip
# sudo ldconfig

sudo -H $PIPBIN install -U --no-binary :all: pip setuptools wheel
$PIPBIN install --user -U --no-binary :all: numpy &
$PIPBIN install --user -U --no-binary :all: pandas &
$PIPBIN install --user -U --no-binary :all: matplotlib &
$PIPBIN install --user -U --no-binary :all: jupyter &
$PIPBIN install --user -U --no-binary :all: ipython &

wait
