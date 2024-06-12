#!/bin/bash
#
# enable_rdp.sh
#

set -e

grdctl rdp enable
grdctl rdp disable-view-only
read -r -s -p "Enter rdp password: " password
grdctl rdp set-credentials kzl "$password"
grdctl status --show-credentials
