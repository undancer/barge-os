#!/usr/bin/env bash

# bargee
qemu-system-x86_64 \
  -nographic \
  -kernel ./iso/boot/bzImage \
  -initrd ./iso/boot/initrd \
  -m 480M \
  -append 'quiet barge.switch_root'
