#! /usr/bin/env bash

set -e

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" >&2
    exit 1
fi

cat > /etc/systemd/system/nfs-ssh-tunnel.service <<EOF
[Unit]
Description=Reverse SSH tunnel for NFS port forwarding (server → remote)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=kzl
ExecStart=/usr/bin/ssh \
  -N \
  -F /home/kzl/.ssh/config \
  -o UserKnownHostsFile=/home/kzl/.ssh/known_hosts \
  -o ExitOnForwardFailure=yes \
  -R 34549:127.0.0.1:2049 LAB
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

nano /etc/systemd/system/nfs-ssh-tunnel.service
systemctl daemon-reload
systemctl enable nfs-ssh-tunnel.service
systemctl start nfs-ssh-tunnel.service
