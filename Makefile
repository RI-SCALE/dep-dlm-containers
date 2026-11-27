SHELL       := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c

IMAGE        ?= fts
TRIVY_VERSION ?= 0.58.1   # pin the current release
TRIVY := docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
           -v $(HOME)/.cache/trivy:/root/.cache aquasec/trivy:$(TRIVY_VERSION)

DIR_rucio-server  := rucio
ARGS_rucio-server := --build-arg RUCIO_COMPONENT=server
DIR_rucio-daemons := rucio
ARGS_rucio-daemons := --build-arg RUCIO_COMPONENT=daemons
DIR_fts           := fts

.DEFAULT_GOAL := help

.PHONY: help
help: ## List targets
	@grep -E '^[a-zA-Z0-9_-]+:.*?## ' $(MAKEFILE_LIST) \
	  | awk -F':.*?## ' '{printf "  %-10s %s\n", $$1, $$2}'

.PHONY: hooks
hooks: ## Install the git pre-commit hook
	pre-commit install

.PHONY: check
check: ## hadolint, shellcheck, YAML via pre-commit
	pre-commit run --all-files

.PHONY: build
build: ## Build IMAGE locally as IMAGE:dev (rucio-server, rucio-daemons, fts)
	docker build $(ARGS_$(IMAGE)) -t $(IMAGE):dev $(DIR_$(IMAGE))

.PHONY: scan
scan: ## Trivy: fixable HIGH/CRITICAL vulnerabilities and secrets in IMAGE:dev
	$(TRIVY) image --scanners vuln,secret --severity HIGH,CRITICAL \
	  --ignore-unfixed --exit-code 1 $(IMAGE):dev