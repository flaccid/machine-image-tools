#! /bin/sh -e

# usage: vmdk_to_ova.sh [vmdk_image_path]

: ${OVF_TEMPLATE_FILE:=templates/basic_template.ovf.xml}

[ -z "$1" ] && echo 'no image file provided, exiting.' && exit 1

image="$1"
base="$(basename $image)"
# the base is the image with the disk1 suffix removed if existing
image_base=`echo ${base%.*} | sed 's/\-disk1//g'`

cp -v "$OVF_TEMPLATE_FILE" "$image_base.ovf"

IMAGE_FILENAME="$image"
IMAGE_SIZE=$(stat --printf="%s" "$image")
IMAGE_CAPACITY=$(qemu-img info "$image" | grep 'virtual size:' | tail -n1 | awk -F " " '{print $NF}')
IMAGE_POPULATED_SIZE=0
IMAGE_UUID=$(vboxmanage showhdinfo "$image" | grep UUID | head -n1 | cut -d ':' -f 2 | xargs)
PRODUCT_INFO='A base RHEL host.'
PRODUCT_NAME="$image_base"
PRODUCT_VERSION='7.2'
: "${PRODUCT_FULL_VERSION:=7.2}"
VENDOR_NAME='Red Hat Inc.'
OPERATING_SYSTEM_INFO='Linux'
OPERATING_SYSTEM_DESCRIPTION='Red Hat Enterprise Linux Guest Machine'

sed -i "s/\$IMAGE_FILENAME/$IMAGE_FILENAME/" "$image_base.ovf"
sed -i "s/\$IMAGE_SIZE/$IMAGE_SIZE/" "$image_base.ovf"
sed -i "s/\$IMAGE_CAPACITY/$IMAGE_CAPACITY/" "$image_base.ovf"
sed -i "s/\$IMAGE_POPULATED_SIZE/$IMAGE_POPULATED_SIZE/" "$image_base.ovf"
sed -i "s/\$IMAGE_UUID/$IMAGE_UUID/" "$image_base.ovf"
sed -i "s/\$PRODUCT_INFO/$PRODUCT_INFO/" "$image_base.ovf"
sed -i "s/\$PRODUCT_NAME/$PRODUCT_NAME/" "$image_base.ovf"
sed -i "s/\$PRODUCT_VERSION/$PRODUCT_VERSION/" "$image_base.ovf"
sed -i "s/\$PRODUCT_FULL_VERSION/$PRODUCT_FULL_VERSION/" "$image_base.ovf"
sed -i "s/\$VENDOR_NAME/$VENDOR_NAME/" "$image_base.ovf"
sed -i "s/\$OPERATING_SYSTEM_INFO/$OPERATING_SYSTEM_INFO/" "$image_base.ovf"
sed -i "s/\$OPERATING_SYSTEM_DESCRIPTION/$OPERATING_SYSTEM_DESCRIPTION/" "$image_base.ovf"
sed -i "s/\$FILENAME_PREFIX/$FILENAME_PREFIX/" "$image_base.ovf"

echo "$image_base.ovf contents:"
echo '--'
cat "$image_base.ovf"
echo '--'

# create mf
cat <<EOF> "$image_base.mf"
SHA1($image)= $(sha1sum $image | cut -d ' ' -f 1)
SHA1($image_base.ovf)= $(sha1sum $image_base.ovf | cut -d ' ' -f 1)
EOF
echo "-- $image_base.mf -- "
cat "$image_base.mf"
echo '----'

# create vmware ova
echo 'Creating ova...'
tar cvf "$image_base.ova" "$image_base.ovf"
tar uvf "$image_base.ova" "$image_base.mf" "$image"
