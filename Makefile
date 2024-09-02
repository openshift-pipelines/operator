# OpenShift Pipelines Operator Makefile
# This makefile aims to help the developer and release captain

SOURCES       = $(shell yq e '.git[].url' upstream/upstream_sources.yaml | sed -e 's|https://github.com/.*/||g')
SOURCES_UP    = $(addprefix sources/, $(addsuffix /upgrade,$(SOURCES)))
OPERATOR_COMMIT = $(shell yq e '.git[0].commit' sources.yaml)

.PHONY: foo
foo:
	echo ${SOURCES}
	echo ${SOURCES_UP}

.PHONY: sources
sources: .sources/operator.$(OPERATOR_COMMIT)
#upstream: .sources/operator.$(OPERATOR_COMMIT) .sources/pipeline.$(PIPELINE_COMMIT)

.sources:
	mkdir -p .sources

.sources/operator.%: .sources
	./hack/checkout-operator.sh $*

.sources/pipeline.%: .sources
	echo pipeline $*

.PHONY: upstream/update
upstream/update:
	./hack/update-operator.sh

.PHONY: components/update
components/update: upstream/update
	./hack/update-components.sh
