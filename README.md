# machine-image-tools

Scripts to convert and manipulate machine images for different virtualisation platforms.

## Requirements

- coreutils
- qemu
- virtualbox

Plus, `curl` and/or `wget` to fetch things like images.

## Usage

### Example

Pull down the Ubuntu 16.04 VMDK and create an OVA:

    $ wget http://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.vmdk
    $ source env/ubuntu-xenial; ./create_images_from_vmdk.sh xenial-server-cloudimg-amd64

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
