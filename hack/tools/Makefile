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
MDBOOK := $(BIN_DIR)/$(GOHOSTOSARCH)/mdbook

# mdBook is a Rust binary, so it is downloaded from the upstream release and
# verified against checksums pinned here. Update the version and every checksum
# together (gh api repos/rust-lang/mdBook/releases/tags/<version> --jq '.assets[] | "\(.name) \(.digest)"').
MDBOOK_VERSION := v0.5.4
ifeq ($(GOHOSTOSARCH),darwin_arm64)
MDBOOK_TARGET := aarch64-apple-darwin
MDBOOK_SHA256 := 03e8a6d8b13a2971e0b3280affd03b388373c1485e26f73407c3a76b0b1838df
else ifeq ($(GOHOSTOSARCH),darwin_amd64)
MDBOOK_TARGET := x86_64-apple-darwin
MDBOOK_SHA256 := a47d7bf0d5d670cff9ee6cce95537cbeb62dc10704d9e7131ffbd13e2b59a5de
else ifeq ($(GOHOSTOSARCH),linux_amd64)
MDBOOK_TARGET := x86_64-unknown-linux-gnu
MDBOOK_SHA256 := 3f28de05dafca9d0f2eab99c662116b0e37b89b1d96a08f8f430b9eeae958cd7
else ifeq ($(GOHOSTOSARCH),linux_arm64)
MDBOOK_TARGET := aarch64-unknown-linux-musl
MDBOOK_SHA256 := 753e5c5c363ee8a56972344dcf91466f005a51db84a7aeffe427ae3ef83d6d44
endif

KUBECTL_VERSION := v1.34.11
KIND_VERSION := v0.33.0
CONTROLLER_TOOLS_VERSION := v0.21.0
GOLANGCI_LINT_VERSION := v2.1.6

.PHONY: help tools controller-gen golangci-lint kind kubectl mdbook clean
help: ## Display available tools
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*?##/ { printf "  %-20s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

tools: controller-gen golangci-lint kind kubectl ## Install all tools
controller-gen: $(CONTROLLER_GEN) ## Install controller-gen
golangci-lint: $(GOLANGCI_LINT) ## Install golangci-lint
kind: $(KIND) ## Install kind
kubectl: $(KUBECTL) ## Install checksum-verified kubectl
mdbook: $(MDBOOK) ## Install checksum-verified mdBook (documentation site; not part of "tools")

$(MDBOOK): Makefile
	@test -n "$(MDBOOK_SHA256)" || { echo "mdbook: no pinned release for $(GOHOSTOSARCH)" >&2; exit 1; }
	@mkdir -p $(@D)
	curl --fail --location --retry 3 https://github.com/rust-lang/mdBook/releases/download/$(MDBOOK_VERSION)/mdbook-$(MDBOOK_VERSION)-$(MDBOOK_TARGET).tar.gz --output $@.tar.gz
	python3 -c 'import hashlib, pathlib, sys; assert hashlib.sha256(pathlib.Path(sys.argv[1]).read_bytes()).hexdigest() == sys.argv[2], "mdbook checksum mismatch"' $@.tar.gz $(MDBOOK_SHA256)
	tar -xzf $@.tar.gz -C $(@D) mdbook
	@rm $@.tar.gz

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
