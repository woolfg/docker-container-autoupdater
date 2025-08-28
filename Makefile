shell := /bin/bash

COMPOSE = docker compose

# Version management
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "No tags found")

# Docker Hub settings (for reference only)
UPDATER_IMAGE ?= $(DOCKER_REGISTRY)/$(DOCKER_USER)/docker-container-autoupdater-updater
TRIGGER_IMAGE ?= $(DOCKER_REGISTRY)/$(DOCKER_USER)/docker-container-autoupdater-trigger

.PHONY: help
help: ## help message, list all commands
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"

.PHONY: test
test: test-update ## run tests

.PHONY: test-update
test-update: ## run update simulation test (pulls older image, tags as latest, then tests update)
	bash ./tests/docker-compose-update.sh

.PHONY: build
build: ## build docker image
	$(COMPOSE) build

.PHONY: logs
logs: ## view logs
	$(COMPOSE) logs

.PHONY: up
up: ## start docker container
	@mkdir -p /tmp/docker-autoupdater-test
	$(COMPOSE) up -d

.PHONY: down
down: ## stop docker container
	$(COMPOSE) down -v

.PHONY: shell-%
shell-%: ## run shell in container
	$(COMPOSE) exec $* $(shell)

.PHONY: test-request
test-request: ## send test request to webhook
	curl http://localhost:8080/update-Nohn0lahGh5ahnaeng9Xolaewu2fae

# Version and release management
.PHONY: release
release: ## create a new release tag (interactive)
	@echo "=== Current Version ==="
	@echo "$(VERSION)"
	@echo ""
	@echo "=== Recent Tags ==="
	@git tag -l | tail -5 || echo "No tags found"
	@echo ""
	@echo -n "Enter new version (e.g., v1.0.0): "
	@read NEW_VERSION; \
	if [ -z "$$NEW_VERSION" ]; then \
		echo "No version provided. Aborting."; \
		exit 1; \
	fi; \
	if [[ "$$NEW_VERSION" != v* ]]; then \
		echo "Version must start with 'v' (e.g., v1.0.0)"; \
		exit 1; \
	fi; \
	echo "Creating tag $$NEW_VERSION..."; \
	git tag -a $$NEW_VERSION -m "Release $$NEW_VERSION"; \
	echo "Tag $$NEW_VERSION created"; \
	echo "Push it git push --tags, so GitHub Actions will build and publish the Docker images."

# Development helpers
.PHONY: clean
clean: ## remove local docker images and containers
	$(COMPOSE) down --volumes --rmi local 2>/dev/null || true

.PHONY: status
status: ## show git and docker status
	@echo "=== Git Status ==="
	@git status --porcelain
	@echo ""
	@echo "=== Current Version ==="
	@echo "$(VERSION)"
	@echo ""
	@echo "=== Recent Tags ==="
	@git tag -l | tail -5 || echo "No tags found"