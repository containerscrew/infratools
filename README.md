<p align="center" >
    <img src="logo.png" alt="logo" width="250"/>
<h3 align="center">infratools</h3>
<p align="center">Container image with infra tools (tofu, terragrunt, aws cli, helm, kubectl...). Useful for CI/CD or local deployments.</p>
</p>

---

![Docker Pulls](https://img.shields.io/docker/pulls/containerscrew/infratools)
![Docker Image Size (full)](https://img.shields.io/docker/image-size/containerscrew/infratools/latest?label=image%20size%20full)
![Docker Image Size (ci)](https://img.shields.io/docker/image-size/containerscrew/infratools/latest-ci?label=image%20size%20ci)
![GitHub last commit](https://img.shields.io/github/last-commit/containerscrew/infratools)
![GitHub issues](https://img.shields.io/github/issues/containerscrew/infratools)
![GitHub Tag](https://img.shields.io/github/v/tag/containerscrew/infratools)

---

# Architecture

| Arch  | Supported | Tested |
| ----- | --------- | ------ |
| amd64 | ✅        | ✅     |
| arm64 | ✅        | ✅     |

# Usage

Create a copy of the script [`run-infratools.sh`](run-infratools.sh) in your repository and run it.

```shell
./run-infratools.sh
Usage: /usr/local/bin/run-infratools.sh [-i (info)] [-u (update)] [-a (attach or create)] [-v <host_path>:<container_path>]
```

Mapping volumes:

```shell
./run-infratools.sh -a -v ~/.lacework.toml:/home/infratools/.lacework.toml
```

Move this script to your bin path, and reuse it in other repos:

```shell
sudo cp run-infratools.sh /usr/local/bin/
```

With this script, you can run the container or attach to an existing, update the container to the latest tag version, or get the current version of the container.

> [!IMPORTANT]
> Running this script, ZSH history will be saved in /code repository to allow persistent command history.
> If you run the script, a new file `.zsh_container_history` will be created to persist history. If you don't want to push it to your git repo, add it to `.gitignore`.

Run the container directly, without mapping directories:

```shell
docker run -it --rm --name infratools containerscrew/infratools:3.3.0
```

In a pipeline like `.gitlab-ci.yml`, you can use the image directly:

```yaml
stages:
  - deploy

infratools:
  image: containerscrew/infratools:3.3.0
  stage: deploy
  script:
    - terraform init
    - terraform plan
    #etc...
```

## CI flavor

A lightweight companion image is published alongside every release under the `-ci` suffix, in the same repository.

Built from the same `Dockerfile` using a separate stage (`--target ci`), it includes only the tools needed for deploy pipelines: `kubectl`, `helm`, `aws-cli`, `jq`, and `curl`. No terraform, no zsh, no local tooling.

```yaml
stages:
  - deploy

deploy:
  image: containerscrew/infratools:3.2.0-ci
  stage: deploy
  script:
    - kubectl version --client
    - helm version
    - aws --version
```

Persist variables in a container:

```shell
cd your-terraform-repo
mkdir .user/
touch .user/env
echo "FOO=BAR" >> .user/env
# Infratools container will use .user/env file as a --envfile
run-infratools.sh -a
echo $FOO
```

> [!IMPORTANT]
> Add `.user/env` to your `.gitignore`

# Local

Full image:

```shell
make local-build-run
```

CI image:

```shell
make ci-local-build-run
```

Trivy image scan:

```bash
make trivy-scan
```

# Versioning

Versions of packages and tools are pinned in the [`Dockerfile`](./Dockerfile). Take a look to the corresponding `tag`.

> [!NOTE]
> From now on, new releases will be tagged without the letter v at the beginning of the tag. Starting from version 3.0.0, it is no longer used.

> [!IMPORTANT]
> Starting in version `v2.9.0` `terraform` was removed in favour of `opentofu`, which is a drop-in replacement for `terraform` CLI.
> `terragrunt` will detect automatically `tofu` binary.
> `tfenv` stills works to manage versions of `terraform`.
> `tofuenv` will be installed in future versions of `infratools` to manage versions of `opentofu`.

If you want to use `terraform` instead of `tofu`:

```shell
tfenv use 1.9.5 # or the version you want
# If using Mac Apple Silicion, and want to use amd64 terraform binary
TFENV_ARCH="amd64" tfenv use 1.9.5
terragrunt init --tf-path=/usr/local/bin/terraform
terragrunt plan --tf-path=/usr/local/bin/terraform
# Or export the variable
TG_TF_PATH=/usr/local/bin/terraform
terragrunt plan
```

# Git config for servers with self signed certificate

If using custom git repository with self signed certificate (eg: terraform modules in a private git server), just edit in your `~/.gitconfig`:

```bash
[http "https://gitlab.server.internal"]
  ##################################
  # Self Signed Server Certificate #
  ##################################

  sslCAInfo = /path/to/your/certificate.crt
  #sslCAPath = /path/to/selfCA/
  sslVerify = true # or set to false if you trust
```

Or skip tls verify, run this inside the container:

```shell
git config --global http.sslVerify false # add this line if needed in run.sh script to run it automatically
```

# Release workflow

Releases are managed with [cocogitto](https://docs.cocogitto.io/) using conventional commits.

## Full image

```shell
# Commit using cog
cog commit feat -a "add new tool X"
cog commit fix -a "update kubectl version"

# Bump to a specific version (updates CHANGELOG.md and creates the git tag)
cog bump --version 3.2.0
git push origin main --follow-tags
```

`cog bump --version` updates `CHANGELOG.md`, commits it, and creates the git tag (e.g. `3.2.0`). This triggers `release.yml` and publishes `infratools:3.2.0`.

## CI image

The CI image shares the same version as the full image. Both are built and published automatically from the same git tag via `release.yml`:

- `infratools:3.2.0` — full image
- `infratools:3.2.0-ci` — CI image

# CHANGELOG

Starting in version `3.0.0` _CHANGELOG.md_ was generated using conventional commits and [`cocogitto`](https://docs.cocogitto.io/).

# LICENSE

`infratools` is distributed under the terms of the [`Apache 2.0`](./LICENSE) license.
