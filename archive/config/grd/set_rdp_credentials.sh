#!/bin/bash

grdctl status --show-credentials
read -r -s -p "Enter password: " password
echo
grdctl rdp set-credentials kzl "$password"
grdctl status --show-credentials
