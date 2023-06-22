#!/bin/bash
#
# install-software.sh
#

sudo apt update
sudo apt upgrade -y
sudo apt install software-properties-common apt-transport-https

### microsoft
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo install -o root -g root -m 644 /dev/stdin /etc/apt/trusted.gpg.d/microsoft.gpg
# sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge-dev.list'
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main"
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
