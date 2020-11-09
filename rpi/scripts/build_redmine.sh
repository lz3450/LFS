#!/bin/bash

set -e

BUILDDIR=/dev/shm
REDMINE_HOME=~/redmine

REDMINEVER=4.1.1

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

sudo -u postgres createdb -O redmine redmine

cd redmine-$REDMINEVER
cd config
cp database.yml.example database.yml
cp configuration.yml.example configuration.yml
tee database.yml << EOF
production:
  adapter: postgresql
  database: redmine
  host: localhost
  username: redmine
  password: "kzl@redmine"
EOF

mkdir -p $REDMINE_HOME/attachments
tee configuration.yml << EOF
default:
  email_delivery:
    delivery_method: :smtp
    smtp_settings:
      enable_starttls_auto: true
      address: smtp.office365.com
      port: 587
      domain: kzl.net
      authentication: :login
      user_name: zelun.kong@outlook.com
      password: K31405302zl

  attachments_storage_path: /home/kzl/redmine/attachments

  autologin_cookie_name:
  autologin_cookie_path:
  autologin_cookie_secure:

  scm_subversion_command:
  scm_mercurial_command:
  scm_git_command:
  scm_cvs_command:
  scm_bazaar_command:

  scm_subversion_path_regexp:
  scm_mercurial_path_regexp:
  scm_git_path_regexp:
  scm_cvs_path_regexp:
  scm_bazaar_path_regexp:
  scm_filesystem_path_regexp:

  scm_stderr_log_file:

  database_cipher_key:

  minimagick_font_path:

production:

development:

EOF

cd $REDMINE_HOME/redmine-$REDMINEVER
# sudo gem install bundler
bundle install --without development test
bundle exec rake generate_secret_token
RAILS_ENV=production bundle exec rake db:migrate
# reset database
# RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rake db:reset
RAILS_ENV=production bundle exec rake redmine:load_default_data
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

systemctl --user daemon-reload
systemctl --user start redmine.service
systemctl --user enable redmine.service
