#! /bin/bash -e

[ -z "$1" ] && echo 'No image name provided.' && exit 1 || image="$1"

# user specified template variables
: "${OVF_TEMPLATE:=templates/basic_template.ovf.xml}"
: "${PRODUCT_INFO:=A Linux Host}"
: "${PRODUCT_VERSION:=latest}"
: "${PRODUCT_FULL_VERSION:=latest}"
: "${VENDOR_NAME:=ACME Inc.}"
: "${OPERATING_SYSTEM_INFO:=Linux}"
: "${OPERATING_SYSTEM_DESCRIPTION:=Linux}"
: "${OPERATING_SYSTEM_ID:=101}"
: "${OPERATING_SYSTEM_VERSION:=16.04}"
: "${OPERATING_SYSTEM_TYPE:=Linux 64-Bit}"

# ensure the contrib/ is in path
export PATH="$PATH:$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../contrib"
# echo "PATH=$PATH"

verify_image()
{
	echo 'verifying checksum...'
	if sha256sum "$1" | grep "$IMAGE_SHA256SUM"; then
		echo 'checksum matches.'
		return 0
	else
		echo 'checksum does not match.'
		return 1
	fi
}

image=$(basename "$IMAGE_URL")
ext="${image##*.}"

echo "create images from $image"

# verify checksum
if [ ! -e "$image" ]; then
	echo "--> fetching $IMAGE_URL"
	curl -LSs "$IMAGE_URL" > "$image"
	! verify_image "$image" && exit 1
else
	echo 'file already downloaded.'
	! verify_image "$image" && exit 1
fi

# derived template variables
PRODUCT_NAME="$image"
IMAGE_FILENAME="$image-disk1.vmdk"
IMAGE_SIZE=$(wc -c "$image-disk1.vmdk" | awk {'print $1'})
IMAGE_CAPACITY=$(qemu-img info "$image-disk1.vmdk" | grep 'virtual size:' | tail -n1 | awk -F " " '{print $NF}')
IMAGE_POPULATED_SIZE=0
IMAGE_UUID=$(vboxmanage showhdinfo "$image-disk1.vmdk" | grep UUID | head -n1 | cut -d ':' -f 2 | xargs)

# copy from source template
cp -v "$OVF_TEMPLATE" "$image.ovf"

# render the template
sed -i -e "s/\$IMAGE_FILENAME/$IMAGE_FILENAME/" "$image.ovf"
sed -i -e "s/\$IMAGE_SIZE/$IMAGE_SIZE/" "$image.ovf"
sed -i -e "s/\$IMAGE_CAPACITY/$IMAGE_CAPACITY/" "$image.ovf"
sed -i -e "s/\$IMAGE_POPULATED_SIZE/$IMAGE_POPULATED_SIZE/" "$image.ovf"
sed -i -e "s/\$IMAGE_UUID/$IMAGE_UUID/" "$image.ovf"
sed -i -e "s/\$PRODUCT_INFO/$PRODUCT_INFO/" "$image.ovf"
sed -i -e "s/\$PRODUCT_NAME/$PRODUCT_NAME/" "$image.ovf"
sed -i -e "s/\$PRODUCT_VERSION/$PRODUCT_VERSION/" "$image.ovf"
sed -i -e "s/\$PRODUCT_FULL_VERSION/$PRODUCT_FULL_VERSION/" "$image.ovf"
sed -i -e "s/\$VENDOR_NAME/$VENDOR_NAME/" "$image.ovf"
sed -i -e "s/\$OPERATING_SYSTEM_INFO/$OPERATING_SYSTEM_INFO/" "$image.ovf"
sed -i -e "s/\$OPERATING_SYSTEM_DESCRIPTION/$OPERATING_SYSTEM_DESCRIPTION/" "$image.ovf"
sed -i -e "s/\$OPERATING_SYSTEM_ID/$OPERATING_SYSTEM_ID/" "$image.ovf"
sed -i -e "s/\$OPERATING_SYSTEM_VERSION/$OPERATING_SYSTEM_VERSION/" "$image.ovf"
sed -i -e "s/\$OPERATING_SYSTEM_TYPE/$OPERATING_SYSTEM_TYPE/" "$image.ovf"

echo "$image.ovf contents:"
echo '--'
cat "$image.ovf"
echo '--'

# create mf
cat <<EOF> "$image.mf"
SHA1($image-disk1.vmdk)= $(shasum -a 1 $image-disk1.vmdk | cut -d ' ' -f 1)
SHA1($image.ovf)= $(shasum -a 1 $image.ovf | cut -d ' ' -f 1)
EOF
echo "-- $image.mf -- "
cat "$image.mf"
echo '----'

# create vmware ova
echo 'Creating ova...'
tar cvf "$image.ova" "$image.ovf"
tar uvf "$image.ova" "$image.mf" "$image-disk1.vmdk"

echo 'Done.'
