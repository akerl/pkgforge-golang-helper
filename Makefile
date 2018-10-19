.PHONY: default local build release manual clean lint vet fmt test deps init update custom

HELPER_PATH := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

include Makefile.local
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null)
export GOPATH = $(CURDIR)/.gopath
BIN = $(GOPATH)/bin
export PATH := $(BIN):$(PATH)
BASEDIR = $(GOPATH)/src/$(NAMESPACE)
BASE = $(BASEDIR)/$(PACKAGE)
GOFILES = $(shell find . -type f -name '*.go' ! -path './.*' ! -path './vendor/*')
OSLIST ?= linux darwin

GO = go
GOFMT = gofmt
GOX = $(BIN)/gox
GOLINT = $(BIN)/golangci-lint
GODEP = $(BIN)/dep

default: build

local: $(BASE) custom deps $(GOX) fmt lint vet test
ifdef LIB_ONLY
	@echo "Skipping build for library-only repo"
else
	cd $(BASE) && $(GOX) \
		-ldflags '-X $(NAMESPACE)/$(PACKAGE)/cmd.Version=$(VERSION)' \
		-gocmd="$(GO)" \
		-output="bin/$(PACKAGE)_{{.OS}}" \
		-os="$(OSLIST)" \
		-arch="amd64"
	@echo "Build completed"
endif

custom:
	if [[ -e custom.sh ]] ; then ./custom.sh ; fi

clean:
	rm -rf $(GOPATH) bin vendor

lint: $(BASE) deps $(GOLINT)
	cd $(BASE) && $(GOLINT) run --enable-all --exclude-use-default=false

vet:
	cd $(BASE) && $(GO) vet ./...

fmt:
	@echo "Running gofmt on $(GOFILES)"
	@files=$$($(GOFMT) -l $(GOFILES)); if [ -n "$$files" ]; then \
		  echo "Error: '$(GOFMT)' needs to be run on:"; \
		  echo "$${files}"; \
		  exit 1; \
		  fi;

test: deps
	cd $(BASE) && $(GO) test ./...

init: $(BASE) $(GODEP)
	cd $(BASE) && $(GODEP) init

update: $(BASE) $(GODEP)
	cd $(BASE) && $(GODEP) ensure -update

status: $(BASE) $(GODEP)
	cd $(BASE) && $(GODEP) status $(STATUS_FLAGS)

deps: $(BASE) $(GODEP)
	cd $(BASE) && $(GODEP) ensure

$(BASEDIR):
	mkdir -p $(BASEDIR)

$(BASE): $(BASEDIR)
	ln -s $(CURDIR) $(BASE)

$(GOLINT): $(BASE)
	$(GO) get github.com/golangci/golangci-lint/cmd/golangci-lint

$(GOX): $(BASE)
	$(GO) get github.com/mitchellh/gox

$(GODEP): $(BASE)
	$(GO) get github.com/golang/dep/cmd/dep

PKGFORGE_MAKE = make -f $(HELPER_PATH)/pkgforge-helper/Makefile

manual:
	$(PKGFORGE_MAKE) manual

build:
	$(PKGFORGE_MAKE)

release:
	$(PKGFORGE_MAKE) release

