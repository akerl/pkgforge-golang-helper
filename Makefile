.PHONY: default local custom clean lint fmt test manual build release

HELPER_PATH := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
PKGFORGE_MAKE = make -f $(HELPER_PATH)/pkgforge-helper/Makefile

include Makefile.local

VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null)
OSLIST ?= linux darwin
GOFILES = $(shell find . -type f -name '*.go' ! -path './.gopath/*')

export GOPATH = $(CURDIR)/.gopath
BIN = $(GOPATH)/bin
export PATH := $(BIN):$(PATH)

GO = go
GOFMT = gofmt
GOX = $(BIN)/gox
REVIVE = $(BIN)/revive
GOSEC = $(BIN)/gosec

default: build

local: custom fmt lint test $(GOX)
ifdef LIB_ONLY
	@echo "Skipping build for library-only repo"
else
	$(GOX) \
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
	if [[ -e $(GOPATH) ]] ; then chmod -R a+w $(GOPATH) ; fi
	rm -rf $(GOPATH) bin

lint: $(REVIVE) $(GOSEC)
	$(GO) vet ./...
	$(REVIVE) ./...
	# TODO: Remove gopath hax
	mkdir -p $(GOPATH)/src/$(NAMESPACE)
	ln -s $(CURDIR) $(GOPATH)/src/$(NAMESPACE)/$(PACKAGE)
	cd $(GOPATH)/src/$(NAMESPACE)/$(PACKAGE) &&	$(GOSEC) ./...

fmt:
	@echo "Running gofmt on $(GOFILES)"
	@files=$$($(GOFMT) -l $(GOFILES)); if [ -n "$$files" ]; then \
		echo "Error: '$(GOFMT)' needs to be run on:"; \
		echo "$${files}"; \
		exit 1; \
		fi;

test:
	$(GO) test ./...

manual:
	$(PKGFORGE_MAKE) manual

build:
	$(PKGFORGE_MAKE)

release:
	$(PKGFORGE_MAKE) release

$(GOX):
	$(GO) install github.com/mitchellh/gox

$(REVIVE):
	$(GO) install github.com/mgechev/revive

$(GOSEC):
	$(GO) install github.com/securego/gosec/cmd/gosec
