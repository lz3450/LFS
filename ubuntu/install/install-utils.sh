#!/bin/bash
#
# install-utils.sh
#

set -e

sudo apt update
sudo apt upgrade -y

sudo apt install -y \
    build-essential \
    tmux \
    samba \
    landscape-client
