<p align="center" >
    <img src="logo.png" alt="logo" width="250"/>
<h3 align="center">infratools</h3>
<p align="center">Container image with infra tools (terraform, terragrunt, aws cli, helm, kubectl...). Useful for CI/CD.</p>
</p>

<!-- START OF TOC !DO NOT EDIT THIS CONTENT MANUALLY-->
**Table of Contents**  *generated with [mtoc](https://github.com/containerscrew/mtoc)*
- [Badges](#badges)
- [About](#about)
- [Available tools](#available-tools)
  - [Versioning](#versioning)
  - [Dynamically change terraform version](#dynamically-change-terraform-version)
  - [Installing python libraries](#installing-python-libraries)
    - [Use pipx to install python packages/libraries](#use-pipx-to-install-python-packages/libraries)
    - [Use venv](#use-venv)
    - [Force installation](#force-installation)
- [Architecture](#architecture)
- [Lint](#lint)
- [Image security scan with Trivy](#image-security-scan-with-trivy)
  - [Local trivy scan](#local-trivy-scan)
- [Running locally](#running-locally)
  - [Mapping volumes to the container](#mapping-volumes-to-the-container)
- [TODO](#todo)
- [CHANGELOG](#changelog)
- [LICENSE](#license)
<!-- END OF TOC -->

![example](./example.png)

# Badges

![Build Status](https://github.com/containerscrew/infratools/actions/workflows/build.yml/badge.svg)
![Build Status](https://github.com/containerscrew/infratools/actions/workflows/hadolint.yml/badge.svg)
[![License](https://img.shields.io/github/license/containerscrew/infratools)](/LICENSE)
![Latest Tag](https://img.shields.io/github/v/tag/containerscrew/infratools?sort=semver)

[![DockerHub Badge](http://dockeri.co/image/containerscrew/infratools)](https://hub.docker.com/r/containerscrew/infratools/)


#  About

How many times do you need a container image with tools like `terraform, helm, kubectl, aws cli, terragrunt`... among many others? Aren't you tired of having to maintain all of them in each repository, instead of having one **"general"** one that can be used in multiple repos?

**Available tags:** https://hub.docker.com/r/containerscrew/infratools/tags

# Available tools

| Tool                                                 | Available |
|------------------------------------------------------|----------|
| Terraform                                            |   ✅      |
| Terragrunt                                           |   ✅      |
| Kubectl                                              |   ✅      |
| Helm                                                 |   ✅      |
| AWS CLI                                              |   ✅      |
| [tftools](https://github.com/containerscrew/tftools) |   ✅      |
| [tfenv](https://github.com/tfutils/tfenv)   |   ✅      |
| [ohmyzsh](https://ohmyz.sh/)   |   ✅      |

Take a look to all the available installed tools inside the [Dockerfile](./Dockerfile)

## Versioning

> Alpine core packages: https://pkgs.alpinelinux.org/packages

> AWS cli v2 is installed directly from official alpine repository. If you need to look for other version, [visit this page](https://pkgs.alpinelinux.org/packages?name=aws-cli&branch=edge&repo=&arch=&maintainer=)

> For every new version, a new git tag will be created. You can see versioning inside [Dockerfile](./Dockerfile)

## Dynamically change terraform version

> [!TIP]
> By default, a version of terraform is installed using `tfenv`. If you have the `.terraform-version` file in your `terraform/terragrunt` repository, `tfenv` should detect the version and install it automatically.


Or change it yourself, for example, within a pipeline:

```shell
tfenv use 1.5.5
```

## Installing python libraries

<details>
<summary>You can install python libraries using `pip3`. BTW, you will see the following error:</summary>
<br>
Error:
<br><br>
<pre>
× This environment is externally managed
╰─>
    The system-wide python installation should be maintained using the system
    package manager (apk) only.

    If the package in question is not packaged already (and hence installable via
    "apk add py3-somepackage"), please consider installing it inside a virtual
    environment, e.g.:

    python3 -m venv /path/to/venv
    . /path/to/venv/bin/activate
    pip install mypackage

    To exit the virtual environment, run:

    deactivate

    The virtual environment is not deleted, and can be re-entered by re-sourcing
    the activate file.

    To automatically manage virtual environments, consider using pipx (from the
    pipx package).

note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
hint: See PEP 668 for the detailed specification.
</pre>
</details>

### Use pipx to install python packages/libraries

Install library + deps:

```shell
pipx install boto3 --include-deps
```

Install a package:

```shell
pipx install your-package-name # visit pypip
```

### Use venv

```shell
python3 -m venv /path/to/venv
. /path/to/venv/bin/activate
pip3 install mypackage
```

### Force installation

```shell
pip3 install boto3 --break-system-packages
```

# Architecture

| Arch    | Supported | Tested |
|---------|----------|--------|
| amd64   | ✅        | ✅        |
| arm64   | ✅         | ✅         |

# Lint

```shell
make hadolint
```

# Image security scan with Trivy

This image uses [trivy github action](https://github.com/aquasecurity/trivy-action) as a tool for security scanning.

Take a look to the [official repo](https://github.com/aquasecurity/trivy) of Trivy.

## Local trivy scan

[Install trivy](https://aquasecurity.github.io/trivy/test/getting-started/installation/)

```shell
make build-image
make trivy-scan # trivy image docker.io/containerscrew/infratools:test
```

# Running locally

```shell
make local-build
make local-run
# Or all in one
make local-build-run
```

> Use other version([tag](https://github.com/containerscrew/infratools/tags)) if needed (edit the Makefile).

## Mapping volumes to the container

Example `run-local-container.sh`:

```shell
#!/bin/bash

CONTAINER_NAME="infratools"
CONTAINER_VERSION="v2.1.0"

if [ $(docker ps | grep ${CONTAINER_NAME} | wc -l) -gt 0 ];then
    docker exec -ti ${CONTAINER_NAME} zsh
else
    docker run -tid \
        --name ${CONTAINER_NAME} \
        --rm \
        -h ${CONTAINER_NAME} \
        -v $(pwd)/:/code \
        -v ~/.ssh:/home/infratools/.ssh \
        -v ~/.aws:/home/infratools/.aws \
        -v ~/.kube:/home/infratools/.kube \
        -v ~/.zsh_history/:/home/infratools/.zsh_history \
        -w /code/ \
        -e AWS_DEFAULT_REGION=eu-west-1 \
#        --dns 1.1.1.1 \
        docker.io/containerscrew/infratools:${CONTAINER_VERSION}
    docker exec -it ${CONTAINER_NAME} zsh
fi
```

# TODO

* Add other dynamic version switchers for other tools (tgswitch, kubectl...)
* Automatic pipeline cron with image scan & automatic build

# CHANGELOG

[CHANGELOG.md](./CHANGELOG.md)

# LICENSE

[LICENSE](./LICENSE)
