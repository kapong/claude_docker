# Maintainer tooling only: build, test, and publish the claude_docker image.
# End users do not need this — they use the `claude_docker` CLI.

IMAGE     ?= ghcr.io/kapong/claude_docker:latest
PLATFORMS ?= linux/amd64,linux/arm64

.DEFAULT_GOAL := help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-8s\033[0m %s\n", $$1, $$2}'

build: ## Build the image for the local arch (for testing)
	docker build -t $(IMAGE) .

test: build ## Build, then smoke-test the tooling inside the image
	docker run --rm --entrypoint sh $(IMAGE) -lc '\
		set -e; whoami; node --version; claude --version; rtk --version; \
		git --version; python3 --version; rg --version | head -1; jq --version'

login: ## Log in to GHCR using your gh token
	gh auth token | docker login ghcr.io -u $$(gh api user --jq .login) --password-stdin

push: login ## Build multi-arch and push to GHCR
	@docker buildx inspect claude_docker-builder >/dev/null 2>&1 || \
		docker buildx create --name claude_docker-builder --driver docker-container >/dev/null
	docker buildx build --builder claude_docker-builder \
		--platform $(PLATFORMS) -t $(IMAGE) --push .

.PHONY: help build test login push
