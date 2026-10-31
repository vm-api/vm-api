# SPDX-License-Identifier: Apache-2.0
# Install host tools independently of the API module's dependencies.
SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

GOHOSTOS := $(shell go env GOHOSTOS)
GOHOSTARCH := $(shell go env GOHOSTARCH)
GOHOSTOSARCH := $(GOHOSTOS)_$(GOHOSTARCH)
export GOOS := $(GOHOSTOS)
export GOARCH := $(GOHOSTARCH)
BIN_DIR := bin

CONTROLLER_GEN := $(BIN_DIR)/$(GOHOSTOSARCH)/controller-gen
GOLANGCI_LINT := $(BIN_DIR)/$(GOHOSTOSARCH)/golangci-lint
KIND := $(BIN_DIR)/$(GOHOSTOSARCH)/kind
KUBECTL := $(BIN_DIR)/$(GOHOSTOSARCH)/kubectl

KUBECTL_VERSION := v1.34.11
KIND_VERSION := v0.33.0
CONTROLLER_TOOLS_VERSION := v0.21.0
GOLANGCI_LINT_VERSION := v2.1.6

.PHONY: help tools controller-gen golangci-lint kind kubectl clean
help: ## Display available tools
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*?##/ { printf "  %-20s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

tools: controller-gen golangci-lint kind kubectl ## Install all tools
controller-gen: $(CONTROLLER_GEN) ## Install controller-gen
golangci-lint: $(GOLANGCI_LINT) ## Install golangci-lint
kind: $(KIND) ## Install kind
kubectl: $(KUBECTL) ## Install checksum-verified kubectl

$(KUBECTL): Makefile
	@mkdir -p $(@D)
	curl --fail --location --retry 3 https://dl.k8s.io/release/$(KUBECTL_VERSION)/bin/$(GOHOSTOS)/$(GOHOSTARCH)/kubectl --output $@.download
	curl --fail --location --retry 3 https://dl.k8s.io/release/$(KUBECTL_VERSION)/bin/$(GOHOSTOS)/$(GOHOSTARCH)/kubectl.sha256 --output $@.sha256
	python3 -c 'import hashlib, pathlib, sys; p = pathlib.Path(sys.argv[1]); assert hashlib.sha256(p.read_bytes()).hexdigest() == pathlib.Path(sys.argv[2]).read_text().strip(), "kubectl checksum mismatch"' $@.download $@.sha256
	chmod +x $@.download
	mv $@.download $@
	@rm $@.sha256

$(KIND): Makefile
	GOBIN=$(abspath $(BIN_DIR)/$(GOHOSTOSARCH)) go install sigs.k8s.io/kind@$(KIND_VERSION)

$(CONTROLLER_GEN): Makefile
	GOBIN=$(abspath $(BIN_DIR)/$(GOHOSTOSARCH)) \
	go install sigs.k8s.io/controller-tools/cmd/controller-gen@$(CONTROLLER_TOOLS_VERSION)

$(GOLANGCI_LINT): Makefile
	GOBIN=$(abspath $(BIN_DIR)/$(GOHOSTOSARCH)) \
	go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@$(GOLANGCI_LINT_VERSION)


clean: ## Remove installed tools
	rm -rf $(BIN_DIR)
