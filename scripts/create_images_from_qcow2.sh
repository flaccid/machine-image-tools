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

# ensure the contrib/ is in path
export PATH="$PATH:$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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
	echo "--> fetching $image..."
	curl -LSs "$IMAGE_URL" > "$image"
	! verify_image "$image" && exit 1
else
	echo 'file already downloaded.'
	! verify_image "$image" && exit 1
fi

# unarchive if needed etc.

# strip out extension(s)
image="${image%.*}"

# convert qcow2 to raw
echo 'Converting to raw...'
qemu-img convert "$image.qcow2" "$image.img"

# convert qcow2 to vmdk
echo 'Converting to vmdk...'
# qemu-img convert -f qcow2 -O vmdk "$image.qcow2" "$image-disk1.vmdk"
# python2.7 /usr/lib/python2.7/dist-packages/VMDKstream.py "$image.img" "$image-disk1.vmdk"
img-convert "$image.qcow2" vmdk-stream "$image-disk1.vmdk"
qemu-img info "$image-disk1.vmdk"
# vboxmanage showhdinfo "$image-disk1.vmdk"

cp -v "$OVF_TEMPLATE" "$image.ovf"

IMAGE_FILENAME="$image-disk1.vmdk"
IMAGE_SIZE=$(stat --printf="%s" "$image-disk1.vmdk")
IMAGE_CAPACITY=$(qemu-img info "$image-disk1.vmdk" | grep 'virtual size:' | tail -n1 | awk -F " " '{print $NF}')
IMAGE_POPULATED_SIZE=0
IMAGE_UUID=$(vboxmanage showhdinfo "$image-disk1.vmdk" | grep UUID | head -n1 | cut -d ':' -f 2 | xargs)
PRODUCT_INFO='A base RHEL host.'
PRODUCT_NAME="$image"
PRODUCT_VERSION='7.2'
PRODUCT_FULL_VERSION='7.2-20151102.0'
VENDOR_NAME='Red Hat Inc.'
OPERATING_SYSTEM_INFO='Linux'
OPERATING_SYSTEM_DESCRIPTION='Red Hat Enterprise Linux Guest Machine'

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
