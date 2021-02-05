#!/bin/sh -e

# usage: vhd_to_vmdk.sh [vhd_image_path]

[ -z "$1" ] && echo 'no vhd file provided, exiting.' && exit 1

image="$1"
base="$(basename $image)"
image_base="${base%.*}"

echo "Converting $base to vmdk..."
qemu-img convert "$image" -O vmdk "$image_base-disk1.vmdk" -p
qemu-img info "$image_base-disk1.vmdk"
