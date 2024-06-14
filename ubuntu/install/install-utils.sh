#!/bin/bash
#
# install-utils.sh
#

set -e

apt-get update
apt-get upgrade -y

apt-get install -y \
    build-essential \
    tmux \
    landscape-client
