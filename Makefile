.PHONY: default local custom clean lint fmt test manual build release tidy

HELPER_PATH := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
PKGFORGE_MAKE = make -f $(HELPER_PATH)/pkgforge-helper/Makefile

include Makefile.local

MOD_PATH = $(shell go list -m)
VERSION_VAR_PATH ?= cmd.Version

VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null)
OSARCHLIST ?= darwin/amd64 darwin/arm64 linux/amd64 linux/arm linux/arm64
OUTPUT_FORMAT ?= bin/$(PACKAGE)_{{.OS}}_{{.Arch}}
GOFILES = $(shell find . -type f -name '*.go' ! -path './.gopath/*')

export GOPATH = $(CURDIR)/.gopath
BIN = $(GOPATH)/bin
export PATH := $(BIN):$(PATH)

TOOLPATH = $(CURDIR)/.tools

GO = go
GOFMT = gofmt
GOX = $(BIN)/gox
REVIVE = $(BIN)/revive

default: build

tidy:
	$(GO) mod tidy

local: custom tidy fmt lint test $(GOX)
ifdef LIB_ONLY
	@echo "Skipping build for library-only repo"
else
	$(GOX) \
		-ldflags '-X $(MOD_PATH)/$(VERSION_VAR_PATH)=$(VERSION)' \
		-gocmd="$(GO)" \
		-output="$(OUTPUT_FORMAT)" \
		-osarch="$(OSARCHLIST)" \
		${GOX_EXTRA_FLAGS}
	@echo "Build completed"
endif

custom:
	if [[ -e custom.sh ]] ; then ./custom.sh ; fi

clean:
	if [[ -e $(GOPATH) ]] ; then chmod -R a+w $(GOPATH) ; fi
	rm -rf $(GOPATH) $(TOOLPATH) bin Dockerfile

lint: $(REVIVE)
	$(GO) vet ./...
	$(REVIVE) -formatter stylish -config $(HELPER_PATH)/revive.toml ./...

fmt:
	@echo "Running gofmt on $(GOFILES)"
	@files=$$($(GOFMT) -l $(GOFILES)); if [ -n "$$files" ]; then \
		echo "Error: '$(GOFMT)' needs to be run on:"; \
		echo "$${files}"; \
		exit 1; \
		fi;

test:
	$(GO) test ./...

manual: Dockerfile
	$(PKGFORGE_MAKE) manual

build: Dockerfile
	$(PKGFORGE_MAKE)

release: Dockerfile
	$(PKGFORGE_MAKE) release

Dockerfile:
ifneq ("$(wildcard Dockerfile.local)","")
	cp Dockerfile.local Dockerfile
else
	cp $(HELPER_PATH)/Dockerfile ./Dockerfile
endif

$(GOX): $(TOOLPATH)
	cd $(TOOLPATH) && $(GO) install github.com/akerl/gox@b420b2b

$(REVIVE): $(TOOLPATH)
	cd $(TOOLPATH) && $(GO) install github.com/mgechev/revive@latest

$(TOOLPATH): $(TOOLPATH)/go.mod

$(TOOLPATH)/go.mod:
	mkdir -p $(TOOLPATH)
	cd $(TOOLPATH) && go mod init tools
