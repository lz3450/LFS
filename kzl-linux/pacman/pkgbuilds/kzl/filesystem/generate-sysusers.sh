#!/usr/bin/env bash

set -euo pipefail

test -f group
test -f passwd


while read -r line; do
  groupname=$(echo "${line}" | cut -d: -f1)
  gid=$(echo "${line}" | cut -d: -f3)
  echo "g ${groupname} ${gid}"
done <group >20-basic-groups.conf

while read -r line; do
  username=$(echo "${line}" | cut -d: -f1)
  uid=$(echo "${line}" | cut -d: -f3)
  gid=$(echo "${line}" | cut -d: -f4)
  gecos=$(echo "${line}" | cut -d: -f5)
  homedir=$(echo "${line}" | cut -d: -f6)
  if [ "${homedir}" == "/" ]; then
    homedir="-"
  fi
  shell=$(echo "${line}" | cut -d: -f7)
  if [ "${shell}" == "/usr/sbin/nologin" ]; then
    shell="-"
  fi
  echo "u ${username} ${uid}:${gid} \"${gecos}\" ${homedir} ${shell}"
done <passwd >20-basic-users.conf
