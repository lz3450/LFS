#!/bin/bash

mkdir -p ~/aria2/downloads
mkdir -p ~/.config/aria2/
mkdir -p ~/.config/systemd/user/

cp aria2.conf ~/.config/aria2/aria2.conf
cp aria2-rpc.conf ~/.config/aria2/aria2-rpc.conf
cp aria2cd.service ~/.config/systemd/user/aria2cd.service
touch ~/aria2/aria2.log
touch ~/aria2/aria2.session
touch ~/aria2/aria2-rpc.log
touch ~/aria2/aria2-rpc.session
