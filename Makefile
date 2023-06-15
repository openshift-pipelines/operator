SHELL := bash

GO           = go
TIMEOUT_UNIT = 20m
TIMEOUT_E2E  = 1h20m

MODULE   = $(shell env GO111MODULE=on $(GO) list -m)
DATE         ?= $(shell date +%FT%T%z)
KO_DATA_PATH  = $(shell pwd)/cmd/operator/kodata

BIN      = $(CURDIR)/.bin

all: test

check: test

# Tests
TEST_UNIT_TARGETS := test-unit-verbose test-unit-race test-unit-failfast
test-unit-verbose: ARGS=-v
test-unit-failfast: ARGS=-failfast
test-unit-race:    ARGS=-race
$(TEST_UNIT_TARGETS): test-unit
test-clean:  ## Clean testcache
	@echo "Cleaning test cache"
	@go clean -testcache 
.PHONY: $(TEST_UNIT_TARGETS) test test-unit
test: test-clean test-unit ## Run test-unit
test-unit: ## Run unit tests
	@echo "Running unit tests..."
	@set -o pipefail ; \
		$(GO) test $(GO_TEST_FLAGS) -timeout $(TIMEOUT_UNIT) $(ARGS) ./... | { grep -v 'no test files'; true; }

.PHONY: test-e2e-cleanup
test-e2e-cleanup: ## cleanup test e2e namespace/pr left open
	@./hack/dev/e2e-tests-cleanup.sh

.PHONY: test-e2e
test-e2e:  test-e2e-cleanup ## run e2e tests
	@go test $(GO_TEST_FLAGS) -timeout $(TIMEOUT_E2E)  -failfast -count=1 -tags=e2e $(GO_TEST_FLAGS) ./test
