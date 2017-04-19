#! /bin/bash -e

# basic process:
# 1. download qcow image if needed
# 2. convert to raw (.img)
# 3. convert to vmdk
# 4. render ovf
# 5. create mf
# 6. create ova

# build deps: curl, tar, qemu-utils, virtualbox

: "${IMAGE_URL:=http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2}"
: "${IMAGE_SHA256SUM:=0cfd71bfbb4dba3097999dcbe1e611d6c3407f1b30936e9a6e437f320dfb7be9}"
: "${FILENAME_PREFIX:=$(basename "$IMAGE_URL")}"

# user specified template variables
: "${OVF_TEMPLATE:=../templates/basic_template.ovf.xml}"
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

image_filename="${IMAGE_URL##*/}"
# image_ext="${image_filename##*.}"

echo "create images from $image_filename"

# verify checksum
if [ ! -e "$image_filename" ]; then
	echo "--> fetching $IMAGE_URL"
	curl -LSs "$IMAGE_URL" > "$image_filename"
	! verify_image "$image_filename" && exit 1
else
	echo 'file already downloaded.'
	! verify_image "$image_filename" && exit 1
fi

# TODO
# unarchive if needed etc.

# convert qcow2 to raw
echo "converting $image_filename to raw..."
qemu-img convert "$image_filename" "$FILENAME_PREFIX.img"

# convert qcow2 to vmdk
# 		of note:
# 			qemu-img convert -f qcow2 -O vmdk "$image.qcow2" "$image-disk1.vmdk"
# 			python2.7 /usr/lib/python2.7/dist-packages/VMDKstream.py "$image.img" "$image-disk1.vmdk"
echo "converting $image_filename to vmdk..."
img-convert "$image_filename" vmdk-stream "$FILENAME_PREFIX-disk1.vmdk"
qemu-img info "$FILENAME_PREFIX-disk1.vmdk"

# vboxmanage showhdinfo "$image-disk1.vmdk"

# mv the file to dest prefix (this can be improved)
mv "$image_filename" "$FILENAME_PREFIX.qcow2" || true

# copy the ovf template
cp -v "$OVF_TEMPLATE" "$FILENAME_PREFIX.ovf"

IMAGE_FILENAME="$FILENAME_PREFIX-disk1.vmdk"
IMAGE_SIZE=$(stat --printf="%s" "$FILENAME_PREFIX-disk1.vmdk")
IMAGE_CAPACITY=$(qemu-img info "$FILENAME_PREFIX-disk1.vmdk" | grep 'virtual size:' | tail -n1 | awk -F " " '{print $NF}')
IMAGE_UUID=$(vboxmanage showhdinfo "$FILENAME_PREFIX-disk1.vmdk" | grep UUID | head -n1 | cut -d ':' -f 2 | xargs)
PRODUCT_NAME="$FILENAME_PREFIX"

# derived template variables
IMAGE_POPULATED_SIZE=0

# render the template
sed -i -e "s/\$IMAGE_FILENAME/$IMAGE_FILENAME/" "$FILENAME_PREFIX.ovf"
sed -i -e "s/\$IMAGE_SIZE/$IMAGE_SIZE/" "$FILENAME_PREFIX.ovf"
sed -i -e "s/\$IMAGE_CAPACITY/$IMAGE_CAPACITY/" "$FILENAME_PREFIX.ovf"
sed -i -e "s/\$IMAGE_POPULATED_SIZE/$IMAGE_POPULATED_SIZE/" "$FILENAME_PREFIX.ovf"
sed -i -e "s/\$IMAGE_UUID/$IMAGE_UUID/" "$FILENAME_PREFIX.ovf"
sed -i -e "s/\$PRODUCT_INFO/$PRODUCT_INFO/" "$FILENAME_PREFIX.ovf"
sed -i -e "s/\$PRODUCT_NAME/$PRODUCT_NAME/" "$FILENAME_PREFIX.ovf"
sed -i -e "s/\$PRODUCT_VERSION/$PRODUCT_VERSION/" "$FILENAME_PREFIX.ovf"
sed -i -e "s/\$PRODUCT_FULL_VERSION/$PRODUCT_FULL_VERSION/" "$FILENAME_PREFIX.ovf"
sed -i -e "s/\$VENDOR_NAME/$VENDOR_NAME/" "$FILENAME_PREFIX.ovf"
sed -i -e "s/\$OPERATING_SYSTEM_INFO/$OPERATING_SYSTEM_INFO/" "$FILENAME_PREFIX.ovf"
sed -i -e "s%\$OPERATING_SYSTEM_DESCRIPTION%$OPERATING_SYSTEM_DESCRIPTION%" "$FILENAME_PREFIX.ovf"
sed -i -e "s/\$OPERATING_SYSTEM_ID/$OPERATING_SYSTEM_ID/" "$FILENAME_PREFIX.ovf"
sed -i -e "s/\$OPERATING_SYSTEM_VERSION/$OPERATING_SYSTEM_VERSION/" "$FILENAME_PREFIX.ovf"
sed -i -e "s/\$OPERATING_SYSTEM_TYPE/$OPERATING_SYSTEM_TYPE/" "$FILENAME_PREFIX.ovf"

echo "$FILENAME_PREFIX.ovf contents:"
echo '--'
cat "$FILENAME_PREFIX.ovf"
echo '--'

# create mf
cat <<EOF> "$FILENAME_PREFIX.mf"
SHA1($FILENAME_PREFIX-disk1.vmdk)= $(sha1sum $FILENAME_PREFIX-disk1.vmdk | cut -d ' ' -f 1)
SHA1($FILENAME_PREFIX.ovf)= $(sha1sum $FILENAME_PREFIX.ovf | cut -d ' ' -f 1)
EOF
echo "-- $FILENAME_PREFIX.mf -- "
cat "$FILENAME_PREFIX.mf"
echo '----'

# create vmware ova
echo 'Creating ova...'
tar cvf "$FILENAME_PREFIX.ova" "$FILENAME_PREFIX.ovf"
tar uvf "$FILENAME_PREFIX.ova" "$FILENAME_PREFIX.mf" "$FILENAME_PREFIX-disk1.vmdk"

echo 'Done.'
