---
name: bump-tools
description: Bump the Alpine base image and pinned tool versions (helm, kubectl, aws-cli, opentofu, terragrunt) in this infratools Dockerfile, build and smoke-test both image flavors locally, gate on a clean Trivy scan, then cut and push the release via cocogitto. Use when asked to update tool versions, refresh the container image, or ship a new infratools release. Also use for vague phrasings, in any language, asking whether anything in this repo is outdated or needs updating.
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
- `full` stage: `HELM_VERSION`, `KUBECTL_VERSION`, `TOFU_VERSION`, `TERRAGRUNT_VERSION`, `KUBELOGIN_VERSION`, `AWSCLI_VERSION`

## 2. Fetch latest available versions

- Alpine: `curl -s https://hub.docker.com/v2/repositories/library/alpine/tags?page_size=25` — pick the latest stable `X.Y`, skip `edge`/`rc`.
- Helm: `curl -s https://api.github.com/repos/helm/helm/releases/latest`
- kubectl: `curl -s https://dl.k8s.io/release/stable.txt`
- OpenTofu: `curl -s https://api.github.com/repos/opentofu/opentofu/releases/latest`
- Terragrunt: `curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest`
- kubelogin: `curl -s https://api.github.com/repos/int128/kubelogin/releases/latest`
- **aws-cli is special**: it's pinned as an Alpine *apk* package (`aws-cli=${AWSCLI_VERSION}`), not upstream's release. The version must exist in that Alpine release's repo — check `https://pkgs.alpinelinux.org/packages?name=aws-cli` for the branch matching `ALPINE_VERSION`, don't just take upstream's latest tag.

Only edit the ARGs that actually changed, minimal diff.

## 3. Build both flavors locally

Don't use `make local-build-run`/`make ci-local-build-run` — they drop into an
interactive shell and won't return. Build directly instead:

```shell
docker build --target full -t localhost/infratools:test .
docker build --target ci -t localhost/infratools:test-ci .
```

If `apk` fails with `DNS: transient error` / `SERVFAIL` (the podman machine
resolver can flake behind the VPN), add `--dns 1.1.1.1` to both builds.

Smoke-test the bumped tools non-interactively. Wrap each command in `sh -c`,
otherwise the shell passes `kubectl version --client` as a single executable
name and `docker run` fails with "executable file not found":

```shell
for c in "kubectl version --client" "helm version" "tofu --version" \
         "terragrunt --version" "aws --version" "kubectl-oidc_login --version"; do
  docker run --rm localhost/infratools:test sh -c "$c"
done
for c in "kubectl version --client" "helm version" "aws --version"; do
  docker run --rm localhost/infratools:test-ci sh -c "$c"
done
```

## 4. Trivy gate

Scan the two images already built in step 3 (`make trivy-scan` rebuilds the
image without `--dns` and can fail on a flaky resolver):

```shell
trivy image --severity HIGH,CRITICAL --exit-code 1 --no-progress localhost/infratools:test
trivy image --severity HIGH,CRITICAL --exit-code 1 --no-progress localhost/infratools:test-ci
```

This fails on any HIGH/CRITICAL finding. If it fails, **stop** and report the
flagged packages (target binary, package, installed vs fixed version), and
see if a newer patch of the affected tool/base clears it before retrying.

Most findings here are Go stdlib / `golang.org/x/*` deps embedded in upstream
binaries (kubectl, helm, terragrunt, kubelogin), which we can't fix. If every
tool is already at its latest upstream version and the findings are only
those embedded deps, report it and let the user decide whether to ship
anyway: `release.yml`'s own Trivy job is `continue-on-error`, so it won't
block a real release. Don't decide that for them.

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
5. `git push origin main --follow-tags`, then `git push origin X.Y.Z`
   explicitly: `--follow-tags` alone has not pushed the new tag here. The tag
   push is what fires `release.yml` and publishes both image flavors to
   Docker Hub. Do this yourself as the final step; don't stop to ask first —
   reaching this point already means build + smoke test + Trivy passed (or
   the user explicitly okayed shipping past the Trivy findings).

## Commit conventions

Follow `AGENTS.md`: Conventional Commits via `cog commit`, terse, no
Claude/AI attribution or co-author lines anywhere in this repo's commits.
