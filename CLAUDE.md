# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commit conventions

- All commits are Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, ...).
- Keep commit messages terse: a single-line summary, body only when strictly necessary.
- Never add Claude/AI attribution or co-author lines to commits or PRs in this repo.

## Commands

```shell
make local-build-run      # Build + run the full image locally (/bin/zsh)
make ci-local-build-run   # Build + run the CI image locally (/bin/sh)
make hadolint             # Lint the Dockerfile
make trivy-scan           # Build full image + scan with Trivy (HIGH,CRITICAL, fails on find)
make install-script        # Copy run-infratools.sh to /usr/local/bin
```

Pre-commit hooks (`.pre-commit-config.yaml`): merge-conflict markers, end-of-file-fixer, trailing-whitespace, gitleaks. Run with `pre-commit run -a`.

Releases use [cocogitto](https://docs.cocogitto.io/) (`cog.toml`), driven off conventional commits:

```shell
cog commit feat -a "..."
cog commit fix  -a "..."
cog bump --version X.Y.Z   # updates CHANGELOG.md, creates git tag
git push origin main --follow-tags
```

Pushing a tag triggers `release.yml`, which builds and publishes both image flavors (`X.Y.Z` and `X.Y.Z-ci`).

## Architecture

`Dockerfile` is a single multi-stage build with a shared `base` stage (Alpine, arch detection) and two leaf targets:

- **`ci` stage** — minimal: `kubectl`, `helm`, `aws-cli`, `jq`, `curl`. Built with `docker build --target ci`. Published as `<version>-ci`.
- **`full` stage** — everything in `ci` plus OpenTofu, Terragrunt, tfenv, zsh/oh-my-zsh, krew (+ oidc-login plugin), kubectx, docker-cli, pre-commit. Published as `<version>` (no suffix).

Both flavors are built and tagged from the same `Dockerfile` and the same git tag — tool versions are pinned via `ARG`s per stage (versions can differ between `ci` and `full`, e.g. `kubectl`).

`run-infratools.sh` is the local dev-shell wrapper distributed separately from the image (copied into a repo or installed to `$PATH`, see `make install-script`). It wraps `docker run`/`docker exec` to:

- mount the current repo at `/code`, plus `~/.aws`, `~/.kube`, `~/.ssh` from the host,
- optionally load `.user/env` as an env-file and persist zsh history to `.zsh_container_history` (both meant to be gitignored in the *consuming* repo),
- support extra bind mounts via repeated `-v host:container`,
- track the container's running version against the latest published tag (queried from the Docker Hub registry API) to decide whether `-u` should recreate it.

`terragrunt`/`tofu` auto-detect the `tofu` binary; `tfenv` is included in the `full` image for repos still pinned to classic `terraform`.
