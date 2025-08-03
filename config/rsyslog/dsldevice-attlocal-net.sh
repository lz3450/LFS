#!/usr/bin/env bash

set -e

LOG_FILE=/var/log/dsldevice-attlocal-net.log

sudo touch "$LOG_FILE"
sudo chown syslog:adm "$LOG_FILE"
sudo chmod 660 "$LOG_FILE"

sudo cp dsldevice-attlocal-net.conf /etc/rsyslog.d/
sudo systemctl restart rsyslog
