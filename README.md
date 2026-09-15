<p align="center">
  <img src="logo.png" alt="infratools logo" width="220"/>
</p>

<h1 align="center">infratools</h1>

<p align="center">
  <em>A batteries-included container image for infrastructure work — OpenTofu, Terragrunt, kubectl, Helm, AWS CLI and more.</em>
  <br/>
  <strong>Use it in CI/CD pipelines or as a portable local dev shell.</strong>
</p>

<p align="center">
  <a href="https://hub.docker.com/r/containerscrew/infratools"><img src="https://img.shields.io/docker/pulls/containerscrew/infratools?logo=docker&logoColor=white" alt="Docker Pulls"/></a>
  <a href="https://hub.docker.com/r/containerscrew/infratools"><img src="https://img.shields.io/docker/image-size/containerscrew/infratools/latest?label=full%20image&logo=docker&logoColor=white" alt="Full image size"/></a>
  <a href="https://hub.docker.com/r/containerscrew/infratools"><img src="https://img.shields.io/docker/image-size/containerscrew/infratools/latest-ci?label=ci%20image&logo=docker&logoColor=white" alt="CI image size"/></a>
  <a href="https://github.com/containerscrew/infratools/releases"><img src="https://img.shields.io/github/v/tag/containerscrew/infratools?label=version&logo=github" alt="Latest version"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/containerscrew/infratools" alt="License"/></a>
  <a href="https://github.com/containerscrew/infratools/commits/main"><img src="https://img.shields.io/github/last-commit/containerscrew/infratools" alt="Last commit"/></a>
</p>

---

<details>
<summary><strong>Table of contents</strong></summary>

- [Why infratools?](#why-infratools)
- [Supported architectures](#supported-architectures)
- [What's inside](#whats-inside)
- [Quick start](#quick-start)
- [Image flavors](#image-flavors)
  - [Full image](#full-image)
  - [CI image](#ci-image)
- [The `run-infratools.sh` helper](#the-run-infratoolssh-helper)
- [Pipeline examples](#pipeline-examples)
- [Working with Terraform vs OpenTofu](#working-with-terraform-vs-opentofu)
- [Self-signed git servers](#self-signed-git-servers)
- [Local development](#local-development)
- [Releases & versioning](#releases--versioning)
- [Changelog](#changelog)
- [License](#license)

</details>

---

## Why infratools?

Setting up `kubectl`, `helm`, `aws-cli`, `terragrunt` and friends on every laptop and CI runner is tedious and drifts over time. `infratools` packages a curated, version-pinned set of infra tools into a single OCI image you can pull from anywhere.

- **Two flavors** — a lightweight `-ci` image for pipelines, and a full local shell with zsh, krew, fzf, and dev ergonomics.
- **Multi-arch** — published for both `amd64` and `arm64`.
- **Pinned versions** — every tool version is declared in the [`Dockerfile`](./Dockerfile) and bumped through conventional commits.

---

## Supported architectures

| Architecture | Supported | Tested |
| ------------ | :-------: | :----: |
| `amd64`      |    ✅     |   ✅   |
| `arm64`      |    ✅     |   ✅   |

---

## What's inside

| Tool                  | Full image | CI image |
| --------------------- | :--------: | :------: |
| `kubectl`             |     ✅     |    ✅    |
| `helm`                |     ✅     |    ✅    |
| `aws-cli`             |     ✅     |    ✅    |
| `jq` / `curl`         |     ✅     |    ✅    |
| `opentofu`            |     ✅     |    —     |
| `terragrunt`          |     ✅     |    —     |
| `tfenv`               |     ✅     |    —     |
| `krew` + `oidc-login` |     ✅     |    —     |
| `kubectx`             |     ✅     |    —     |
| `git` / `vim`         |     ✅     |    —     |
| `zsh` + `oh-my-zsh`   |     ✅     |    —     |
| `fzf`, `bash`, `make` |     ✅     |    —     |
| `pre-commit`          |     ✅     |    —     |
| `docker-cli`          |     ✅     |    —     |
| `openssh` (krb5)      |     ✅     |    —     |

> [!NOTE]
> Exact pinned versions live in the [`Dockerfile`](./Dockerfile) under the `ARG` declarations.

---

## Quick start

> [!WARNING]
> Avoid using `:latest` in real workflows. Tool versions (OpenTofu, Terragrunt, kubectl, Helm…) change between releases and may break compatibility with your modules or state files.
> Pin an explicit version from [Docker Hub tags](https://hub.docker.com/r/containerscrew/infratools/tags) or [GitHub releases](https://github.com/containerscrew/infratools/tags) — for example `containerscrew/infratools:3.4.0`. The `:latest` tags in the snippets below are shown for brevity only.

Mount your project directory and your local AWS / kube / SSH config so the container can act on your real environment:

```shell
docker run -it --rm \
  --name infratools \
  -h infratools \
  -v "$(pwd):/code" \
  -v "$HOME/.aws:/home/infratools/.aws" \
  -v "$HOME/.kube:/home/infratools/.kube" \
  -v "$HOME/.ssh:/home/infratools/.ssh" \
  -w /code \
  containerscrew/infratools:latest
```

> [!TIP]
> For day-to-day local use, prefer the [`run-infratools.sh`](#the-run-infratoolssh-helper) helper — it wires up these mounts (plus env-file and zsh history persistence) automatically.

Or use the image directly in a pipeline:

```yaml
deploy:
  image: containerscrew/infratools:latest-ci
  script:
    - kubectl version --client
    - helm version
    - aws --version
```

---

## Image flavors

### Full image

`containerscrew/infratools:<version>` — the complete toolbox for local development and rich pipelines. Includes OpenTofu, Terragrunt, zsh with oh-my-zsh, krew plugins, and the rest of the table above.

### CI image

`containerscrew/infratools:<version>-ci` — a stripped-down image built from the same `Dockerfile` (`--target ci`). It ships only what most deploy jobs need: `kubectl`, `helm`, `aws-cli`, `jq`, `curl`. No terraform, no zsh, no dev tooling — smaller and faster to pull.

Both flavors are published from the same git tag.

---

## The `run-infratools.sh` helper

For local use, copy [`run-infratools.sh`](run-infratools.sh) into your repo (or your `$PATH`) and run it:

```shell
./run-infratools.sh
# Usage: run-infratools.sh [-i (info)] [-u (update)] [-a (attach or create)] [-v <host_path>:<container_path>] [-p <aws-vault profile>]
```

Install it globally so you can reuse it from any repo:

```shell
sudo cp run-infratools.sh /usr/local/bin/
```

**Mount additional files** (e.g. credentials):

```shell
run-infratools.sh -a -v ~/.lacework.toml:/home/infratools/.lacework.toml
```

**Persist environment variables** across container runs — create a `.user/env` file in your project:

```shell
cd your-terraform-repo
mkdir -p .user
echo "FOO=BAR" >> .user/env
run-infratools.sh -a
echo "$FOO"   # → BAR
```

**Use `aws-vault` instead of mounting `~/.aws`** — pass a profile with `-p` (or export `AWS_VAULT_PROFILE`):

```shell
run-infratools.sh -a -p my-account.sysops
```

With `-p`, the helper wraps `docker run` in `aws-vault exec` and forwards the short-lived
`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` and `AWS_SESSION_EXPIRATION`
variables into the container. `~/.aws` is **not** mounted in that mode, so no long-lived
credentials or profile config ever reach the container. It also makes multi-account work
explicit: one container per repo, each started against the profile you named.

```shell
# same laptop, two accounts, two containers
cd ~/code/platform-prod  && run-infratools.sh -a -p PlatformProduction.sysops
cd ~/code/tools-prod     && run-infratools.sh -a -p CoreTools.sysops
```

> [!NOTE]
> Credentials are baked into the container's environment when it starts, so they expire with the
> aws-vault session — recreate the container (`docker rm -f <name>` then `run-infratools.sh -a -p ...`)
> to refresh them. If you are already inside an `aws-vault exec` subshell, the helper detects it
> (`$AWS_VAULT`) and reuses those credentials rather than nesting, which `aws-vault` rejects.

> [!IMPORTANT]
> The helper persists zsh history in `.zsh_container_history` at the repo root and reads `.user/env` as an env file.
> Add both to your `.gitignore` to keep them out of version control.

---

## Pipeline examples

**GitLab CI** with the full image:

```yaml
stages:
  - deploy

infratools:
  image: containerscrew/infratools:latest
  stage: deploy
  script:
    - tofu init
    - tofu plan
```

**GitLab CI** with the slim CI image:

```yaml
deploy:
  image: containerscrew/infratools:latest-ci
  stage: deploy
  script:
    - kubectl apply -f manifests/
    - helm upgrade --install my-release ./chart
```

> [!TIP]
> Pin to an explicit version (`:3.4.0` / `:3.4.0-ci`) in production pipelines for reproducible builds.

---

## Working with Terraform vs OpenTofu

> [!IMPORTANT]
> Since `v2.9.0`, `terraform` has been replaced by [`opentofu`](https://opentofu.org/) — a drop-in CLI replacement. `terragrunt` will auto-detect the `tofu` binary.

If you still need the classic `terraform` CLI, `tfenv` is included:

```shell
tfenv use 1.9.5

# Apple Silicon hosts wanting the amd64 binary:
TFENV_ARCH=amd64 tfenv use 1.9.5

# Point terragrunt explicitly at terraform:
terragrunt init --tf-path=/usr/local/bin/terraform
# or via env var:
export TG_TF_PATH=/usr/local/bin/terraform
terragrunt plan
```

---

## Self-signed git servers

When pulling modules from a private git server with a self-signed certificate, configure `~/.gitconfig`:

```ini
[http "https://gitlab.server.internal"]
  sslCAInfo = /path/to/your/certificate.crt
  sslVerify = true
```

Or, inside the container, skip TLS verification (use with care):

```shell
git config --global http.sslVerify false
```

---

## Local development

Build and run the **full** image locally:

```shell
make local-build-run
```

Build and run the **CI** image locally:

```shell
make ci-local-build-run
```

Scan the image with Trivy:

```shell
make trivy-scan
```

---

## Releases & versioning

Releases are managed with [cocogitto](https://docs.cocogitto.io/) and conventional commits.

```shell
# Record commits
cog commit feat -a "add new tool X"
cog commit fix  -a "update kubectl version"

# Bump and tag (updates CHANGELOG.md and creates the git tag)
cog bump --version 3.2.0
git push origin main --follow-tags
```

Pushing the tag triggers `release.yml`, which builds and publishes both flavors:

- `containerscrew/infratools:3.2.0` — full image
- `containerscrew/infratools:3.2.0-ci` — CI image

> [!NOTE]
> Starting in `3.0.0`, tags no longer carry the leading `v` (e.g. `3.2.0`, not `v3.2.0`).

---

## Changelog

Starting in `3.0.0`, [`CHANGELOG.md`](./CHANGELOG.md) is generated from conventional commits via [cocogitto](https://docs.cocogitto.io/).

---

## License

`infratools` is distributed under the terms of the [Apache 2.0](./LICENSE) license.
