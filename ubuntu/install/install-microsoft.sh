#!/bin/bash
#
# install-microsoft.sh
#

set -e

sudo apt update
sudo apt upgrade -y

### microsoft
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo install -o root -g root -m 644 /dev/stdin /etc/apt/trusted.gpg.d/microsoft.gpg
echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" | sudo tee /etc/apt/sources.list.d/microsoft-edge.list
echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
# sudo apt-add-repository "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main"
# sudo apt-add-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
