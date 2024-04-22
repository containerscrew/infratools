SHELL:=/bin/sh
.PHONY: all

help: ## this help
	@awk 'BEGIN {FS = ":.*?## ";  printf "Usage:\n  make \033[36m<target> \033[0m\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*?## / {gsub("\\\\n",sprintf("\n%22c",""), $$2);printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

doctoc: ## Create table of contents with doctoc
	doctoc .

local-build: ## Build the image using podman
	podman build -t localhost/infratools:test .

local-run: ## Run the image locally
	podman rm -fv infratools
	podman run --rm -it --name infratools localhost/infratools:test

trivy-scan: ## Scan image using trivy
	systemctl --user enable --now podman.socket ;\
	trivy image localhost/infratools:test

hadolint: ## Run hadolint
	hadolint Containerfile
