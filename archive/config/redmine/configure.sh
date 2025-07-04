#!/bin/bash

sudo chown -R redmine:redmine /var/lib/redmine/
sudo chown -R redmine:redmine /var/log/redmine/
sudo chown -R redmine:redmine /usr/share/webapps/redmine/db/
sudo chown -R redmine:redmine /usr/share/webapps/redmine/public/plugin_assets

sudo tee /usr/share/webapps/redmine/config/database.yml << EOF
production:
  adapter: postgresql
  database: redmine
  host: localhost
  username: redmine
  password: "redmine@postgresql"
EOF

sudo tee /usr/share/webapps/redmine/config/configuration.yml << EOF
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

  attachments_storage_path:

  autologin_cookie_name:
  autologin_cookie_path:
  autologin_cookie_secure:

  scm_subversion_command:
  scm_mercurial_command:
  scm_git_command: /usr/bin/git
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

cd /usr/share/webapps/redmine

sudo -u redmine -g redmine bundle exec rake generate_secret_token
sudo -u redmine -g redmine RAILS_ENV=production bundle exec rake db:migrate
sudo -u redmine -g redmine RAILS_ENV=production bundle exec rake redmine:load_default_data

# repository
sudo -u redmine -g redmine mkdir ~redmine/repository
sudo -u redmine -g redmine chmod g+w ~redmine/repository
sudo -u redmine -g redmine setfacl -d -m g::rwx ~redmine/repository
