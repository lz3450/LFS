#!/bin/bash
#
# ustreamer.sh
#

libcamerify ustreamer \
    --device=/dev/video0 \
    --resolution=1296x972 \
    --format=YUYV \
    --encoder=hw \
    --host=0.0.0.0 \
    --port=8080