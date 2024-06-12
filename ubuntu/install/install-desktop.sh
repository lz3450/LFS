#!/bin/bash
#
# install-desktop.sh
#

set -e

sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install -y ubuntu-desktop-minimal
