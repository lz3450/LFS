#!/bin/bash
#
# install-desktop.sh
#

set -e

sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install -y ubuntu-desktop-minimal

grdctl rdp enable
grdctl rdp disable-view-only
read -r -s -p "Enter rdp password: " password
grdctl rdp set-credentials kzl "$password"
grdctl status --show-credentials
