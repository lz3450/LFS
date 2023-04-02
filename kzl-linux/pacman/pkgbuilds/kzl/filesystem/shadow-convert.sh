#!/usr/bin/env bash

if [ x`pwd` = "x/etc" ]
then
  echo Cannot operate directly on \"/etc\". >&2
  exit 1
fi

#make prototype for /etc/shadow
sed -e "s/:.*/:*:`expr $(date +%s) / 86400`:0:99999:7:::/" passwd >shadow

#make prototype for /etc/gshadow
sed -e 's/:[0-9]\+:/::/g' group >gshadow

#mark passwd and group files entries shadowed
sed -i -e 's/^\([^:]\+\):[^:]*:/\1:x:/' passwd group

echo Converted successfully.
exit 0
