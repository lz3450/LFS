#!/bin/bash
#
# install-utils.sh
#

set -e

sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install -y \
    build-essential \
    tmux \
    landscape-client
