[![CircleCI](https://circleci.com/gh/flaccid/machine-image-tools/tree/master.svg?style=svg)](https://circleci.com/gh/flaccid/machine-image-tools/tree/master)

# machine-image-tools

Scripts to convert and manipulate machine images for different virtualisation platforms.

## Requirements

- coreutils
- qemu
- virtualbox
- awk
- sed

Plus, `curl` and/or `wget` to fetch things like images.

Installing all of these with your native package manage should be trivial, e.g.

    $ sudo apt-get -y install coreutils qemu virtualbox gawk sed curl wget

## File Names

Proposed general scheme:

```
<prefix>-<version>-<build-date>-<arch>-<suffix>
```

For example, `debian-8.7.3-20170323-amd64.ova`

## Usage

### Examples

Pull down the Ubuntu 16.04 VMDK, create an OVA and upload to vSphere:

    $ . scripts/env/ubuntu-1604 && ./create_images_from_vmdk.sh xenial-server-cloudimg-amd64
    $ ovftool --acceptAllEulas \
       -ds='NFS Datastore' \
       --net:'VM Network'='VM Network' \
       --vmFolder='VM Templates' \
       --X:logToConsole=True \
       --X:logLevel="verbose" \
       --diskMode=thin \
         ./xenial-server-cloudimg-amd64.ova vi://user@vcenter/datacenter1/host/cluster1

Pull down a Debian qcow2 image, create an OVA:

    $ . scripts/env/debian-8 && scripts/create_images_from_qcow2.sh

Pull down a CentOS qcow2 image, create an OVA:

    $ . scripts/env/centos-7 && scripts/create_images_from_qcow2.sh

Pull down a RancherOS qcow2 image, create an OVA:

    $ . scripts/env/rancheros && scripts/create_images_from_qcow2.sh

CoreOS
    $ . scripts/env/coreos-stable && scripts/create_images_from_qcow2.sh

## Downloads

See the [releases](https://github.com/flaccid/machine-image-tools/releases) page. The intent is to provide all possible image formats for the following:

- Debian 8
- Ubuntu 16.04
- CentOS 7
- RancherOS
- CoreOS (stable)

## Upstream Resources

- http://opennodecloud.com/howto/2013/12/25/howto-ON-ovf-reference.html
- https://www.vmware.com/support/developer/ovf/ovf20/ovftool_201_userguide.pdf
- http://wiki.qemu-project.org/Features/Qcow3
- https://github.com/tcnksm/ghr/wiki/Integrate-ghr-with-CI-as-a-Service

### Respected Machine Image Homes

Currently only trusting distro official sites :)

- https://cloud-images.ubuntu.com/
- http://cdimage.debian.org/cdimage/openstack/current/
- http://cloud.centos.org/centos/7/images/

### Alternatives

- https://github.com/djui/docker-vbox-img

License and Authors
-------------------
- Author: Chris Fordham (<chris@fordham-nagy.id.au>)

```text
Copyright 2017, Chris Fordham

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
