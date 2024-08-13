SHELL:=/bin/sh
.PHONY: all

help: ## this help
	@awk 'BEGIN {FS = ":.*?## ";  printf "Usage:\n  make \033[36m<target> \033[0m\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*?## / {gsub("\\\\n",sprintf("\n%22c",""), $$2);printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

doctoc: ## Create table of contents with doctoc
	doctoc .

local-build: ## Build the image using podman
	docker build -t localhost/infratools:test .

local-run: ## Run the image locally
	docker run --rm -it -h containertools --name infratools localhost/infratools:test

local-build-run: local-build local-run ## Build and run the image locally

trivy-scan: ## Scan image using trivy
	systemctl --user enable --now podman.socket ;\
	trivy image localhost/infratools:test

hadolint: ## Run hadolint
	hadolint Containerfile

generate-changelog: ## Generate changelog using git cliff
	git cliff --output CHANGELOG.md
