DATE         ?= $(shell date +%FT%T%z)
REMOTE        = 127.0.0.1
TAG           = latest
RUNTIME       = docker
ENVIRONMENT="devel"
OPM_VERSION=v1.47.0

BIN_DIR := $(CURDIR)/.bin
OS=$(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m | tr '[:upper:]' '[:lower:]' | sed \
  -e 's/x86_64/amd64/' \
  -e 's/arm64/arm64/' \
  -e 's/aarch64/arm64/')

export PATH := $(BIN_DIR):$(PATH)

update-payload-and-version: olm ## Update tektoncd operator build number, payloads, bundle manifests, image references
	@./hack/update-version.sh
	@./hack/operator-fetch-payload.sh
	@./hack/operator-update-images.sh

update-payload-and-reference: olm ## Update tektoncd operator payloads, bundle manifests, image references
	@./hack/update-version.sh
	@./hack/operator-fetch-payload.sh
	@./hack/operator-update-images.sh

fetch-payload: ## Update tektoncd operator payloads and bundle manifests
	@./hack/operator-fetch-payload.sh

update-reference: olm## Update references in the generate clusterserviceversion.yaml
	@./hack/operator-update-images.sh ${ENVIRONMENT}

.PHONY: olm
olm:
	echo "OLM"
	mkdir -p $(BIN_DIR)
	curl -SfLo$(BIN_DIR)/opm https://github.com/operator-framework/operator-registry/releases/download/$(OPM_VERSION)/$(OS)-$(ARCH)-opm
	chmod +x $(BIN_DIR)/opm

FORCE:

.PHONY: help
help:
	@grep -hE '^[ a-zA-Z0-9/_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-32s\033[0m %s\n", $$1, $$2}'
