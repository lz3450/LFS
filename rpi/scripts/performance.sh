#!/bin/bash

echo performance | sudo tee /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
