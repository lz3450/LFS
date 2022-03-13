#!/bin/sh

if [ ! -d /usr/lib/firmware/edid ];
then
    sudo mkdir /usr/lib/firmware/edid
fi

sudo cp -f edid_new.bin /usr/lib/firmware/edid