#!/bin/bash

ARIA2_HOME="$HOME/.aria2"

mkdir -p $ARIA2_HOME/downloads
mkdir -p ~/.config/aria2/
mkdir -p ~/.config/systemd/user/

cp aria2.conf ~/.config/aria2/aria2.conf
cp aria2-rpc.conf ~/.config/aria2/aria2-rpc.conf
cp aria2cd.service ~/.config/systemd/user/
touch $ARIA2_HOME/aria2.log
touch $ARIA2_HOME/aria2.session
touch $ARIA2_HOME/aria2-rpc.log
touch $ARIA2_HOME/aria2-rpc.session

# # aria2-webui
# cp aria2-webui.service ~/.config/systemd/user/
# if [ ! -d $ARIA2_HOME/webui-aria2 ]; then
#     cd $ARIA2_HOME
#     git clone https://github.com/ziahamza/webui-aria2.git
# else
#     cd $ARIA2_HOME/webui-aria2
#     git pull
# fi
