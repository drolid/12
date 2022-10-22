#!/bin/sh

if [ ! -x /usr/bin/mkimage ]; then
    echo 'mkimage not found, please install uboot tools:'
    echo '  sudo apt -y install u-boot-tools'
    exit 1
fi

mkimage -A arm -O linux -T script -C none -n 'u-boot boot script' -d boot.txt boot.scr

