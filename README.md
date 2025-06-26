<p align="center" >
    <img src="logo.png" alt="logo" width="250"/>
<h3 align="center">infratools</h3>
<p align="center">Container image with infra tools (terraform, terragrunt, aws cli, helm, kubectl...). Useful for CI/CD or local deployments.</p>
</p>

---
[![Build and scan 🕷️📦](https://github.com/containerscrew/infratools/actions/workflows/build.yml/badge.svg?event=push)](https://github.com/containerscrew/infratools/actions/workflows/build.yml)
![Hadolint](https://github.com/containerscrew/infratools/actions/workflows/hadolint.yml/badge.svg)
[![License](https://img.shields.io/github/license/containerscrew/infratools)](/LICENSE)
![Latest Tag](https://img.shields.io/github/v/tag/containerscrew/infratools?sort=semver)

[![DockerHub Badge](http://dockeri.co/image/containerscrew/infratools)](https://hub.docker.com/r/containerscrew/infratools/)


> **Available tags:** https://hub.docker.com/r/containerscrew/infratools/tags
---

# Architecture

| Arch    | Supported | Tested |
|---------|----------|--------|
| amd64   | ✅        | ✅        |
| arm64   | ✅         | ✅         |

# Usage

Create a copy of the script [`run-infratools.sh`](run-infratools.sh) in your repository and run it.

```shell
./run-infratools.sh
Usage: ./run-infratools.sh [-i (info)] [-u (update)] [-a (attach)]
```

With this script, you can run the container or attach to an existing, update the container to the latest tag version, or get the current version of the container.

> [!IMPORTANT]
> Running this script, ZSH history will be saved in /code repository to allow persistent command history.
> So, If you don't want to push the .zsh_history to git, add the file to `.gitignore` in the repo you are using.

Or just run the container directly, without mapping directories:

```shell
docker run -it --rm --name infratools containerscrew/infratools:v2.9.0
```

In a pipeline like `.gitlab-ci.yml`, you can use the image directly:

```yaml
stages:
  - deploy

infratools:
  image: containerscrew/infratools:v2.9.0
  stage: deploy
  script:
    - aws --version
    - kubectl version --client
    #etc... 
```

# Local

```shell
make local-build-run
```

# Versioning

Versions of packages and tools are pinned in the [`Dockerfile`](./Dockerfile). Take a look to the corresponding `tag`.

> [!IMPORTANT]
> Starting in version `v2.9.0` `terraform` was removed in favour of `opentofu`, which is a drop-in replacement for `terraform` CLI.
> `terragrunt` will detect automatically `tofu` binary.
> `tfenv` stills works to manage versions of `terraform`.
> `tofuenv` will be installed in future versions of `infratools` to manage versions of `opentofu`.

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

# LICENSE

`infratools` is distributed under the terms of the [`Apache 2.0`](./LICENSE) license.
