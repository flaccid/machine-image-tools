#! /bin/sh -e

# usage: qcow2_to_raw.sh [qcow2_image_path]

[ -z "$1" ] && echo 'no image file provided, exiting.' && exit 1

image="$1"
base="$(basename $image)"
image_base="${base%.*}"

# convert qcow2 to raw
echo "Converting $base to raw..."
qemu-img convert "$image" "$image_base.img"
