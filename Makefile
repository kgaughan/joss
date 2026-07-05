exe = github.com/goss-org/goss/cmd/goss
pkgs = $(shell git ls-files -- '*.go' | xargs dirname | sort -u | xargs -L1 printf "./%s\n")
cmd = goss
GO_FILES = $(shell git ls-files -- '*.go' ':!:*vendor*_test.go')
VENV := $(shell echo $${VIRTUAL_ENV-.venv})
PYTHON := $(VENV)/bin/python
DOCS_DEPS := $(VENV)/.docs.dependencies

.PHONY: all
all: test-short-all test-int-all dgoss-sha256 dcgoss-sha256 kgoss-sha256

.PHONY: test-short-all
test-short-all: fmt lint vet test

.PHONY: test
test:
	go test -coverpkg=./... -coverprofile=c.out ./...

.PHONY: cov
cov: test
	go tool cover -func ./c.out

.PHONY: htmlcov
htmlcov: test
	go tool cover -html ./c.out

.PHONY: lint
lint:
	$(info INFO: Starting build $@)
	go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.12.2
	golangci-lint run --timeout 5m $(pkgs) || true

.PHONY: vet
vet:
	$(info INFO: Starting build $@)
	go vet $(pkgs) || true

.PHONY: fmt
fmt:
	$(info INFO: Starting build $@)
	./ci/go-fmt.sh

.PHONY: bench
bench:
	$(info INFO: Starting build $@)
	go test -bench=.

test-int-validate-%: build
	$(info INFO: Starting build $@)
	./integration-tests/run-validate-tests.sh $*

test-int-serve-%: build
	$(info INFO: Starting build $@)
	./integration-tests/run-serve-tests.sh $*

.PHONY: build
build:
	goreleaser build --clean --snapshot
	mkdir -p release
	cp dist/binaries_linux_amd64_v1/goss release/goss-linux-amd64
	cp dist/binaries_linux_arm64_v8.0/goss release/goss-linux-arm64
	cp dist/binaries_darwin_amd64_v1/goss release/goss-darwin-amd64
	cp dist/binaries_darwin_arm64_v8.0/goss release/goss-darwin-arm64
	cp dist/binaries_windows_amd64_v1/goss.exe release/goss-windows-amd64.exe

.PHONY: gen
gen:
	$(info INFO: Starting build $@)
	go generate -tags genny $(pkgs)

.PHONY: clean
clean:
	$(info INFO: Starting build $@)
	rm -rf c.out
	rm -rf ./dist
	rm -rf ./release
	rm -rf ./site
	rm -rf ${VENV}

# Update the matcher test golden files
update-matcher-tests:
	go test -v -run '^TestMatchers' . -update

.PHONY: test-darwin-all test-linux-all test-windows-all
test-darwin-all: test-short-all test-int-darwin-all
# linux _does_ have the docker-style testing, but does _not_ currently have the same style integration tests darwin+windows do, _because_ of the docker-style testing.
test-linux-all: test-short-all test-int-64
test-windows-all: test-short-all test-int-windows-all

.PHONY: test-int-all test-int-64 test-int-darwin-all test-int-windows-all
test-int-64: rockylinux9 bullseye jammy alpine3 arch test-int-serve-linux-amd64
test-int-darwin-all: test-int-validate-darwin-amd64 test-int-serve-darwin-amd64
test-int-windows-all: test-int-validate-windows-amd64 test-int-serve-windows-amd64
test-int-all: test-int-64

.PHONY: rockylinux9
rockylinux9: build
	$(info INFO: Starting build $@)
	cd integration-tests/ && ./test.sh rockylinux9 amd64
.PHONY: bullseye
bullseye: build
	$(info INFO: Starting build $@)
	cd integration-tests/ && ./test.sh bullseye amd64
.PHONY: jammy
jammy: build
	$(info INFO: Starting build $@)
	cd integration-tests/ && ./test.sh jammy amd64
.PHONY: alpine3
alpine3: build
	$(info INFO: Starting build $@)
	cd integration-tests/ && ./test.sh alpine3 amd64
.PHONY: arch
arch: build
	$(info INFO: Starting build $@)
	cd integration-tests/ && ./test.sh arch amd64

dgoss-sha256:
	cd extras/dgoss/ && sha256sum dgoss > dgoss.sha256

dcgoss-sha256:
	cd extras/dcgoss/ && sha256sum dcgoss > dcgoss.sha256

kgoss-sha256:
	cd extras/kgoss/ && sha256sum kgoss > kgoss.sha256

.PHONY: lint-yaml
lint-yaml:
	$(info INFO: Starting $@)
	yamllint -c .yamllint .

$(PYTHON):
	$(info Creating virtualenv in $(VENV))
	@python3 -m venv $(VENV)

$(DOCS_DEPS): $(PYTHON) docs/requirements.txt
	$(info Installing dependencies)
	@$(VENV)/bin/pip install --upgrade pip
	@$(VENV)/bin/pip install --requirement docs/requirements.txt
	@touch $(DOCS_DEPS)

.PHONY: docs/setup
docs/setup: $(DOCS_DEPS)

.PHONY: docs/serve
docs/serve: docs/setup
	$(info Running documentation live development server)
	@$(VENV)/bin/zensical serve --strict

.PHONY: docs
docs: docs/setup
	$(info Building documentation)
	@$(VENV)/bin/zensical build --strict
