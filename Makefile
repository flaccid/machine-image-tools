WORKING_DIR := $(shell pwd)

.DEFAULT_GOAL := debian-stretch

.PHONY: debian-stretch

clean:: ## removes all various files including all images
		@rm -Rf ./*.qcow2 ./*.raw ./*.vmdk ./*.img ./*.mf ./*.ova ./*.ovf

centos:: ## bakes centos 7 images
		@source ./scripts/env/centos-7 && ./scripts/create_images_from_qcow2.sh

debian-stretch:: ## bakes debian 9 images
		@source ./scripts/env/debian-9 && ./scripts/create_images_from_qcow2.sh

ubuntu-bionic:: ## bakes ubuntu 18.04 LTS images
		@source ./scripts/env/ubuntu-18.04 && ./scripts/create_images_from_vmdk.sh

install-ghr:: ## installs ghr
		@cd /tmp
		@wget https://github.com/tcnksm/ghr/releases/download/v0.5.4/ghr_v0.5.4_linux_amd64.zip
		@unzip ghr_v0.5.4_linux_amd64.zip
		@mv ./ghr /usr/local/bin/

# a help target including self-documenting targets (see the awk statement)
define HELP_TEXT
Usage: make [TARGET]... [MAKEVAR1=SOMETHING]...

Available targets:
endef
export HELP_TEXT
help: ## this help target
	@cat .banner
	@echo
	@echo "$$HELP_TEXT"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / \
		{printf "\033[36m%-30s\033[0m  %s\n", $$1, $$2}' $(MAKEFILE_LIST)
