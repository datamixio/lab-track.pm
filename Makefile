.SILENT :

export GO111MODULE=on

# App name
APPNAME=trackr

# Go configuration
GOOS?=linux
GOARCH?=amd64

# Add exe extension if windows target
is_windows:=$(filter windows,$(GOOS))
EXT:=$(if $(is_windows),".exe","")

# Archive name
ARCHIVE=$(APPNAME)-$(GOOS)-$(GOARCH).tgz

# Executable name
EXECUTABLE=$(APPNAME)$(EXT)

# Extract version infos
PKG_VERSION:=github.com/ncarlier/$(APPNAME)/pkg/version
VERSION:=`git describe --always --dirty`
GIT_COMMIT:=`git rev-list -1 HEAD --abbrev-commit`
BUILT:=`date`
define LDFLAGS
-X '$(PKG_VERSION).Version=$(VERSION)' \
-X '$(PKG_VERSION).GitCommit=$(GIT_COMMIT)' \
-X '$(PKG_VERSION).Built=$(BUILT)'
endef

all: build

# Include common Make tasks
root_dir:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
makefiles:=$(root_dir)/makefiles
include $(makefiles)/help.Makefile

## Clean built files
clean:
	-rm -rf release
	-rm assets/trackr.min.js pkg/assets/statik.go
.PHONY: clean

# Build minified JS
assets/trackr.min.js:
	npm run minify

# Build assets as Go file
pkg/assets/statik.go: assets/trackr.min.js
	echo ">>> Generating \"pkg/assets/statik.go\" ..."
	go get -u github.com/rakyll/statik
	statik -p assets -src assets -dest pkg -f

## Build executable
build: pkg/assets/statik.go
	-mkdir -p release
	echo ">>> Building: $(EXECUTABLE) $(VERSION) for $(GOOS)-$(GOARCH) ..."
	GOOS=$(GOOS) GOARCH=$(GOARCH) go build -ldflags "$(LDFLAGS)" -o release/$(EXECUTABLE)
.PHONY: build

release/$(EXECUTABLE): build

## Run tests
test:
	go test ./...
.PHONY: test

## Install executable
install: release/$(EXECUTABLE)
	echo ">>> Installing $(EXECUTABLE) to ${HOME}/.local/bin/$(EXECUTABLE) ..."
	cp release/$(EXECUTABLE) ${HOME}/.local/bin/$(EXECUTABLE)
.PHONY: install

## Create Docker image
image:
	echo ">>> Building Docker image ..."
	docker build --rm -t ncarlier/$(APPNAME) .
.PHONY: image

# Generate changelog
CHANGELOG.md:
	standard-changelog --first-release

## Create archive
archive: release/$(EXECUTABLE)
	echo ">>> Creating release/$(ARCHIVE) archive..."
	tar czf release/$(ARCHIVE) README.md LICENSE CHANGELOG.md -C release/ $(EXECUTABLE)
	rm release/$(EXECUTABLE)
.PHONY: archive

## Create distribution binaries
distribution: CHANGELOG.md
	GOARCH=amd64 make build archive
	GOARCH=arm64 make build archive
	GOARCH=arm make build archive
	GOOS=darwin make build archive
.PHONY: distribution
