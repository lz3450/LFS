#!/bin/bash

set -e

BUILDDIR=/dev/shm
REDMINE_HOME=~/redmine

REDMINEVER=4.1.1

sudo mount -o remount,size=16G tmpfs $BUILDDIR

sudo apt install -y \
    build-essential patch \
    zlib1g-dev liblzma-dev libpq5 libpq-dev \
    ruby ruby-dev ruby-bundler \
    postgresql postgresql-client ghostscript imagemagick

cd $BUILDDIR
if [ ! -f redmine-4.1.1.tar.gz ]; then
    wget https://www.redmine.org/releases/redmine-$REDMINEVER.tar.gz
fi

if [ -d $REDMINE_HOME ]; then
    echo "$HOME/redmine exists"
    exit 1
fi

mkdir -p $REDMINE_HOME
cd $REDMINE_HOME
tar -xf $BUILDDIR/redmine-$REDMINEVER.tar.gz

cd redmine-$REDMINEVER
cd config
cp database.yml.example database.yml
nano database.yml

cd $REDMINE_HOME/redmine-$REDMINEVER
# sudo gem install bundler
bundle install --without development test
bundle exec rake generate_secret_token
RAILS_ENV=production bundle exec rake db:migrate
# test 
#bundle exec rails server webrick -e production

tee ~/.config/systemd/user/redmine.service << EOF
[Unit]
Description=DSR Redmine
After=network.target

[Service]
Type=simple
WorkingDirectory=$REDMINE_HOME/redmine-$REDMINEVER
ExecStart=/usr/bin/ruby ./bin/rails server webrick -p 3000 -b 0.0.0.0 -e production
RestartSec=60
Restart=always

[Install]
WantedBy=default.target
EOF