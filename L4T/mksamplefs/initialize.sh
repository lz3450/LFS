#!/bin/bash

# user
echo -e '3450\n3450' | passwd root

# zsh
wget -O .zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc
install -Dm644 .zshrc /etc/skel/.zshrc
install -Dm644 .zshrc /etc/zsh/zshrc

wget -O zsh-autosuggestions.deb http://ports.ubuntu.com/ubuntu-ports/pool/universe/z/zsh-autosuggestions/zsh-autosuggestions_0.6.4-1_all.deb
dpkg -i zsh-autosuggestions.deb || :
rm zsh-autosuggestions.deb || :

echo 'source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh' | tee -a /etc/zsh/zshrc
echo 'source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' | tee -a /etc/zsh/zshrc

sudo rm -rf /etc/environment
sudo touch /etc/environment
