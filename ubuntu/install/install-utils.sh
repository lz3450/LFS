#!/bin/bash
#
# install-utils.sh
#

sudo apt update
sudo apt upgrade -y

sudo apt install -y \
    build-essential \
    tmux
