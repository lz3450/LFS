#!/bin/bash
#
# install-app.sh
#

set -e

apt-get update
apt-get upgrade -y

### microsoft
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | install -o root -g root -m 644 /dev/stdin /etc/apt/trusted.gpg.d/microsoft.gpg
echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" | tee /etc/apt/sources.list.d/microsoft-edge.list
echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" | tee /etc/apt/sources.list.d/vscode.list
# sudo apt-add-repository "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main"
# sudo apt-add-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"

apt-get update
apt-get install -s microsoft-edge-stable code | grep "^Inst" | awk '{print $2}' | sort > microsoft-pkgs.txt
apt-get install -y microsoft-edge-stable code
