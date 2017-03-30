#! /bin/sh -e

# usage: raw_to_vmdk.sh [qcow2_image_path]

[ -z "$1" ] && echo 'no image file provided, exiting.' && exit 1

image="$1"
base="$(basename $image)"
image_base="${base%.*}"

# convert qcow2 to vmdk
echo "Converting $base to vmdk..."
# qemu-img convert -f qcow2 -O vmdk "$image.qcow2" "$image-disk1.vmdk"
# python2.7 /usr/lib/python2.7/dist-packages/VMDKstream.py "$image.img" "$image-disk1.vmdk"
./img-convert "$image" vmdk-stream "$image_base-disk1.vmdk"
qemu-img info "$image_base-disk1.vmdk"
# vboxmanage showhdinfo "$image-disk1.vmdk"
