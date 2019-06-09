WORKING_DIR := $(shell pwd)

.DEFAULT_GOAL := debian-stretch

.PHONY: debian-stretch

clean:: ## removes all various files including all images
		@rm -Rf ./dist/*
		@rm -Rf ./*.qcow2 ./*.raw ./*.vmdk ./*.img ./*.mf ./*.ova ./*.ovf

centos:: ## bakes centos 7 images
		@. ./scripts/env/centos-7 && ./scripts/create_images_from_qcow2.sh

debian-stretch:: ## bakes debian 9 images
		@. ./scripts/env/debian-9 && ./scripts/create_images_from_qcow2.sh

ubuntu-bionic:: ## bakes ubuntu 18.04 LTS images
		@. ./scripts/env/ubuntu-18.04 && ./scripts/create_images_from_vmdk.sh

install-ghr:: ## installs ghr
		@cd /tmp
		@wget https://github.com/tcnksm/ghr/releases/download/v0.5.4/ghr_v0.5.4_linux_amd64.zip
		@unzip ghr_v0.5.4_linux_amd64.zip
		@mv ./ghr /usr/local/bin/

todist:: ## moves all available created files to dist/
		mkdir -p dist
		@mv ./*.qcow2 ./dist/
		@mv ./*.vmdk ./dist/
		@mv ./*.img ./dist/
		@mv ./*.mf ./dist/
		@mv ./*.ova ./dist/
		@mv ./*.ovf ./dist/

### temporary workaround removing .img files
# for some reason with this file we see ghr return 422 Validation Failed [{Resource:ReleaseAsset Field:size Code:custom Message:size is not included in the list}]
# its probably just over or hitting the 2GB file size limit
publish:: ## publish the files in dist/ to github
		@rm -f dist/debian-*.img
		@rm -f dist/centos-*.img
		@/usr/local/bin/ghr -t "$$GITHUB_TOKEN" -u "$$CIRCLE_PROJECT_USERNAME" -r "$$CIRCLE_PROJECT_REPONAME" -prerelease -delete "v0.0.$$CIRCLE_BUILD_NUM" dist/

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
