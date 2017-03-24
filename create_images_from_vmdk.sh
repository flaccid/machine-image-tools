#!/bin/sh -e

[ -z "$1" ] && echo 'No image name provided.' && exit 1 || image="$1"

# use the basic template
cp -v templates/basic_template.ovf.xml "$image.ovf"

# user specified template variables
: "${PRODUCT_INFO:=A Linux Host}"
: "${PRODUCT_VERSION:=latest}"
: "${PRODUCT_FULL_VERSION:=latest}"
: "${VENDOR_NAME:=ACME Inc.}"
: "${OPERATING_SYSTEM_INFO:=Linux}"
: "${OPERATING_SYSTEM_DESCRIPTION:=Linux}"

# derived template variables
PRODUCT_NAME="$image"
IMAGE_FILENAME="$image-disk1.vmdk"
IMAGE_SIZE=$(stat --printf="%s" "$image-disk1.vmdk")
IMAGE_CAPACITY=$(qemu-img info "$image-disk1.vmdk" | grep 'virtual size:' | tail -n1 | awk -F " " '{print $NF}')
IMAGE_POPULATED_SIZE=0
IMAGE_UUID=$(vboxmanage showhdinfo "$image-disk1.vmdk" | grep UUID | head -n1 | cut -d ':' -f 2 | xargs)

# render the template
sed -i "s/\$IMAGE_FILENAME/$IMAGE_FILENAME/" "$image.ovf"
sed -i "s/\$IMAGE_SIZE/$IMAGE_SIZE/" "$image.ovf"
sed -i "s/\$IMAGE_CAPACITY/$IMAGE_CAPACITY/" "$image.ovf"
sed -i "s/\$IMAGE_POPULATED_SIZE/$IMAGE_POPULATED_SIZE/" "$image.ovf"
sed -i "s/\$IMAGE_UUID/$IMAGE_UUID/" "$image.ovf"
sed -i "s/\$PRODUCT_INFO/$PRODUCT_INFO/" "$image.ovf"
sed -i "s/\$PRODUCT_NAME/$PRODUCT_NAME/" "$image.ovf"
sed -i "s/\$PRODUCT_VERSION/$PRODUCT_VERSION/" "$image.ovf"
sed -i "s/\$PRODUCT_FULL_VERSION/$PRODUCT_FULL_VERSION/" "$image.ovf"
sed -i "s/\$VENDOR_NAME/$VENDOR_NAME/" "$image.ovf"
sed -i "s/\$OPERATING_SYSTEM_INFO/$OPERATING_SYSTEM_INFO/" "$image.ovf"
sed -i "s/\$OPERATING_SYSTEM_DESCRIPTION/$OPERATING_SYSTEM_DESCRIPTION/" "$image.ovf"

echo "$image.ovf contents:"
echo '--'
cat "$image.ovf"
echo '--'

# create mf
cat <<EOF> "$image.mf"
SHA1($image-disk1.vmdk)= $(sha1sum $image-disk1.vmdk | cut -d ' ' -f 1)
SHA1($image.ovf)= $(sha1sum $image.ovf | cut -d ' ' -f 1)
EOF
echo "-- $image.mf -- "
cat "$image.mf"
echo '----'

# create vmware ova
echo 'Creating ova...'
tar cvf "$image.ova" "$image.ovf"
tar uvf "$image.ova" "$image.mf" "$image-disk1.vmdk"

echo 'Done.'
