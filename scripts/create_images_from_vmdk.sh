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
	if type shasum > /dev/null 2>&1; then
		sha256_cmd='shasum -a 256'
	else
		sha256_cmd='sha256sum'
	fi
	echo 'verifying checksum...'
	if $sha256_cmd "$1" | grep "$IMAGE_SHA256SUM"; then
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
PRODUCT_NAME=${image%-disk1.vmdk}
IMAGE_FILENAME="$image"
IMAGE_SIZE=$(wc -c "$IMAGE_FILENAME" | awk {'print $1'})
IMAGE_CAPACITY=$(qemu-img info "$IMAGE_FILENAME" | grep 'virtual size:' | tail -n1 | awk -F " " '{print $NF}')
IMAGE_POPULATED_SIZE=0
IMAGE_UUID=$(vboxmanage showhdinfo "$IMAGE_FILENAME" | grep UUID | head -n1 | cut -d ':' -f 2 | xargs)

# copy from source template
cp -v "$OVF_TEMPLATE" "$PRODUCT_NAME.ovf"

# render the template
sed -i -e "s/\$IMAGE_FILENAME/$IMAGE_FILENAME/" "$PRODUCT_NAME.ovf"
sed -i -e "s/\$IMAGE_SIZE/$IMAGE_SIZE/" "$PRODUCT_NAME.ovf"
sed -i -e "s/\$IMAGE_CAPACITY/$IMAGE_CAPACITY/" "$PRODUCT_NAME.ovf"
sed -i -e "s/\$IMAGE_POPULATED_SIZE/$IMAGE_POPULATED_SIZE/" "$PRODUCT_NAME.ovf"
sed -i -e "s/\$IMAGE_UUID/$IMAGE_UUID/" "$PRODUCT_NAME.ovf"
sed -i -e "s/\$PRODUCT_INFO/$PRODUCT_INFO/" "$PRODUCT_NAME.ovf"
sed -i -e "s/\$PRODUCT_NAME/$PRODUCT_NAME/" "$PRODUCT_NAME.ovf"
sed -i -e "s/\$PRODUCT_VERSION/$PRODUCT_VERSION/" "$PRODUCT_NAME.ovf"
sed -i -e "s/\$PRODUCT_FULL_VERSION/$PRODUCT_FULL_VERSION/" "$PRODUCT_NAME.ovf"
sed -i -e "s/\$VENDOR_NAME/$VENDOR_NAME/" "$PRODUCT_NAME.ovf"
sed -i -e "s/\$OPERATING_SYSTEM_INFO/$OPERATING_SYSTEM_INFO/" "$PRODUCT_NAME.ovf"
sed -i -e "s/\$OPERATING_SYSTEM_DESCRIPTION/$OPERATING_SYSTEM_DESCRIPTION/" "$PRODUCT_NAME.ovf"
sed -i -e "s/\$OPERATING_SYSTEM_ID/$OPERATING_SYSTEM_ID/" "$PRODUCT_NAME.ovf"
sed -i -e "s/\$OPERATING_SYSTEM_VERSION/$OPERATING_SYSTEM_VERSION/" "$PRODUCT_NAME.ovf"
sed -i -e "s/\$OPERATING_SYSTEM_TYPE/$OPERATING_SYSTEM_TYPE/" "$PRODUCT_NAME.ovf"

echo "$PRODUCT_NAME.ovf contents:"
echo '--'
cat "$PRODUCT_NAME.ovf"
echo '--'

# create mf
cat <<EOF> "$PRODUCT_NAME.mf"
SHA1($IMAGE_FILENAME)= $(shasum -a 1 $image | cut -d ' ' -f 1)
SHA1($PRODUCT_NAME.ovf)= $(shasum -a 1 $PRODUCT_NAME.ovf | cut -d ' ' -f 1)
EOF
echo "-- $PRODUCT_NAME.mf -- "
cat "$PRODUCT_NAME.mf"
echo '----'

# create vmware ova
echo 'Creating ova...'
tar cvf "$PRODUCT_NAME.ova" "$PRODUCT_NAME.ovf"
tar uvf "$PRODUCT_NAME.ova" "$PRODUCT_NAME.mf" "$image"

echo 'Done.'
