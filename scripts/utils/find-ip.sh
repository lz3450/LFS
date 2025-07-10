#!/usr/bin/env bash
#
# find-ip.sh
#   quick /24 network sweep
#
# Usage examples
#   ./find-ip.sh 192.168.1          # scan 192.168.1.0/24
#   ./find-ip.sh                    # auto-detect the first active /24
#
# Requires:
#   bash 4+, ping, getent (or 'host' as a fallback), xargs
#

set -e
set -u
set -o pipefail
# set -x

### pick subnet prefix
if [[ $# -eq 1 ]]; then
    prefix="$1"
else
    # crude auto-detection: first RFC1918 /24 on an UP interface
    prefix=$(ip -4 -o addr show scope global up \
             | awk '{print $4}' | cut -d/ -f1 \
             | awk -F. '$1==10 || $1==172 || $1==192 {print $1"."$2"."$3; exit}')
    [[ -z $prefix ]] && { echo "No active private /24 found; please specify one."; exit 1; }
fi

echo "Scanning ${prefix}.0/24 … (this takes a few seconds)"
printf -- "%-15s  %s\n" "IP address" "Hostname"
printf -- "--------------  ---------------------------\n"

### sweep the network (parallelized)
seq 1 254 | xargs -P 50 -I{} \
    bash -c '
    ip="'"$prefix"'.{}"
    name="–"
    if ping -c1 -W1 -q "$ip" &>/dev/null; then
        if name=$(getent hosts "$ip" | awk "{print \$2}"); then
            :
        elif command -v host &>/dev/null; then
            name=$(host "$ip" 2>/dev/null | awk "/pointer/ {print \$5}" | sed "s/\\.\$//")
            [[ -z $name ]] && name="–"
        fi
        printf "%-15s  %s\n" "$ip" "$name"
    fi
' | sort -V
