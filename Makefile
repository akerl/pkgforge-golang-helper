include Makefile.local

HELPER_PATH := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
PKGFORGE_MAKE = make -f $(HELPER_PATH)/pkgforge-helper/Makefile

VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null)
OSLIST ?= linux darwin

export GOPATH = $(CURDIR)/.gopath

GO = go
GOFMT = gofmt
GOX = gox
GOLINT = golangci-lint

default: build

local: custom deps fmt lint vet test
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

lint:

vet:

fmt:

test:

manual:
	$(PKGFORGE_MAKE) manual

build:
	$(PKGFORGE_MAKE)

release:
	$(PKGFORGE_MAKE) release

$(GOX):
	go get github.com/mitchellh/gox@v0.4.0

$(GOLINT):
	go get github.com/golangci/golangci-lint@v1.12.5

