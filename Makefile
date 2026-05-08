SHELL:=/bin/sh
.PHONY: all

help: ## this help
	@awk 'BEGIN {FS = ":.*?## ";  printf "Usage:\n  make \033[36m<target> \033[0m\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*?## / {gsub("\\\\n",sprintf("\n%22c",""), $$2);printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

local-build: ## Build the full image locally
	docker build --target full -t localhost/infratools:test .

local-run: ## Run the full image locally
	docker run --rm -it -h containertools --name infratools localhost/infratools:test /bin/zsh

local-build-run: local-build local-run ## Build and run the full image locally

ci-local-build: ## Build the ci image locally
	docker build --target ci -t localhost/infratools:test-ci .

ci-local-run: ## Run the ci image locally
	docker run --rm -it -h infratools-ci --name infratools-ci localhost/infratools:test-ci /bin/sh

ci-local-build-run: ci-local-build ci-local-run ## Build and run the ci image locally

trivy-scan: ## Scan image using trivy
	systemctl --user enable --now podman.socket ;\
	trivy image localhost/infratools:test

hadolint: ## Run hadolint
	hadolint Dockerfile

install-script: ## Install run-infratools.sh in your PATH
	sudo cp run-infratools.sh /usr/local/bin
