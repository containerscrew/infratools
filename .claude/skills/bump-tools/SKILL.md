---
name: bump-tools
description: Bump the Alpine base image and pinned tool versions (helm, kubectl, aws-cli, opentofu, terragrunt) in this infratools Dockerfile, build and smoke-test both image flavors locally, gate on a clean Trivy scan, then cut and push the release via cocogitto. Use when asked to update tool versions, refresh the container image, or ship a new infratools release.
---

# Bump tools and ship a release

Goal: keep `Dockerfile`'s pinned versions current, verify locally, and — once
verified — cut the release yourself: propose the next tag and commit, then
run `cog bump` and push it so `release.yml` fires.

## 1. Inventory current pins

Read `Dockerfile` ARGs. Note `ci` and `full` pin `HELM_VERSION`/`KUBECTL_VERSION`
independently — check both stages, they can legitimately differ:

- `ALPINE_VERSION` (base stage)
- `ci` stage: `HELM_VERSION`, `KUBECTL_VERSION`, `AWSCLI_VERSION`
- `full` stage: `HELM_VERSION`, `KUBECTL_VERSION`, `TOFU_VERSION`, `TERRAGRUNT_VERSION`, `AWSCLI_VERSION`

## 2. Fetch latest available versions

- Alpine: `curl -s https://hub.docker.com/v2/repositories/library/alpine/tags?page_size=25` — pick the latest stable `X.Y`, skip `edge`/`rc`.
- Helm: `curl -s https://api.github.com/repos/helm/helm/releases/latest`
- kubectl: `curl -s https://dl.k8s.io/release/stable.txt`
- OpenTofu: `curl -s https://api.github.com/repos/opentofu/opentofu/releases/latest`
- Terragrunt: `curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest`
- **aws-cli is special**: it's pinned as an Alpine *apk* package (`aws-cli=${AWSCLI_VERSION}`), not upstream's release. The version must exist in that Alpine release's repo — check `https://pkgs.alpinelinux.org/packages?name=aws-cli` for the branch matching `ALPINE_VERSION`, don't just take upstream's latest tag.

Only edit the ARGs that actually changed, minimal diff.

## 3. Build both flavors locally

Don't use `make local-build-run`/`make ci-local-build-run` — they drop into an
interactive shell and won't return. Build directly instead:

```shell
docker build --target full -t localhost/infratools:test .
docker build --target ci -t localhost/infratools:test-ci .
```

Smoke-test the bumped tools non-interactively, e.g.:

```shell
docker run --rm localhost/infratools:test kubectl version --client
docker run --rm localhost/infratools:test helm version
docker run --rm localhost/infratools:test tofu --version
docker run --rm localhost/infratools:test terragrunt --version
docker run --rm localhost/infratools:test aws --version
docker run --rm localhost/infratools:test-ci kubectl version --client
docker run --rm localhost/infratools:test-ci aws --version
```

## 4. Trivy gate

```shell
make trivy-scan
```

This fails (`--exit-code 1`) on any HIGH/CRITICAL finding. Treat it as a hard
gate: if it fails, **stop** — report the flagged packages, and see if a newer
patch of the affected tool/base clears it before retrying. Don't commit past
a failing scan.

## 5. Cut and push the release

Only reached once step 4's Trivy gate is clean. All commits go through `cog
commit`, never a raw `git commit`.

1. Commit the version bump: `cog commit feat -a "bump kubectl to 1.37.0, helm
   to 4.2.0"` (bumps are `feat:` per this repo's history — that's what drives
   the minor version tag).
2. Work out the next version cocogitto will produce (`cog bump --auto
   --dry-run` if the installed `cog` supports it, otherwise infer from semver
   given the commit type and current tag).
3. Update `CONTAINER_VERSION` in `run-infratools.sh` to that version:
   `cog commit chore -a "update run-infratools.sh to X.Y.Z"` — this repo
   always does this bump separately, before the cocogitto version-bump
   commit.
4. State the proposed next tag and what's about to happen (one line — this
   is the trigger for a public release), then run `cog bump --auto`. This
   creates the `CHANGELOG.md` update, the `chore(version): X.Y.Z` commit,
   and the git tag.
5. `git push origin main --follow-tags` — this is what fires `release.yml`
   and publishes both image flavors to Docker Hub. Do this yourself as the
   final step; don't stop to ask first — reaching this point already means
   build + smoke test + Trivy all passed.

## Commit conventions

Follow `CLAUDE.md`: Conventional Commits via `cog commit`, terse, no
Claude/AI attribution or co-author lines anywhere in this repo's commits.
