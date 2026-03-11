#!/usr/bin/env bash
#
# pacman-repo-setup.sh
#

set -e

cp -vf pacman-repo /etc/nginx/sites-available/pacman-repo
ln -vrsf /etc/nginx/sites-available/pacman-repo /etc/nginx/sites-enabled/

sudo systemctl reload nginx
