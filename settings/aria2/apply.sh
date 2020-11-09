#!/bin/bash

mkdir -p ~/aria2/downloads
mkdir -p ~/.config/aria2/
mkdir -p ~/.config/systemd/user/

cp aria2.conf ~/.config/aria2/aria2.conf
cp aria2-rpc.conf ~/.config/aria2/aria2-rpc.conf
cp aria2cd.service ~/.config/systemd/user/
cp aria2-webui.service ~/.config/systemd/user/
touch ~/aria2/aria2.log
touch ~/aria2/aria2.session
touch ~/aria2/aria2-rpc.log
touch ~/aria2/aria2-rpc.session

if [ ! -d ~/aria2/webui-aria2 ]; then
    cd ~/aria2
    git clone https://github.com/ziahamza/webui-aria2.git
else
    cd ~/aria2/webui-aria2
    git pull
fi
