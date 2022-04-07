#!/bin/bash

# grml-zsh-config
wget -O rootfs/root/.zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc
echo 'source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> rootfs/root/.zshrc
echo 'source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh' >> rootfs/root/.zshrc
cp ../../config/zsh/oh-my-zsh.sh rootfs/root
