shell := /bin/bash

COMPOSE = docker compose

.PHONY: help
help: ## help message, list all command
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"

.PHONY: build
build: ## build docker image
	$(COMPOSE) build

.PHONY: up
up: ## start docker container
	$(COMPOSE) up

.PHONY: shell-%
shell-%: ## run shell in container
	$(COMPOSE) exec $* $(shell)

.PHONY: test-request
test-request: ## send test request to webhook
	curl http://localhost:8080/update-Nohn0lahGh5ahnaeng9Xolaewu2fae