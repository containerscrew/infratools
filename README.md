<p align="center" >
    <img src="logo.png" alt="logo" width="250"/>
<h3 align="center">infratools</h3>
<p align="center">Container image with infra tools (terraform, terragrunt, aws cli, helm, kubectl...). Useful for CI/CD.</p>
</p>

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Badges](#badges)
- [About](#about)
- [Available tools](#available-tools)
  - [Versioning](#versioning)
  - [Dynamically change terraform version](#dynamically-change-terraform-version)
- [Architecture](#architecture)
- [Image security scan with Trivy](#image-security-scan-with-trivy)
  - [Local trivy scan](#local-trivy-scan)
- [Running locally](#running-locally)
  - [Rootless (podman)](#rootless-podman)
    - [Mapping volumes with podman unshare](#mapping-volumes-with-podman-unshare)
    - [Git errors after unshare](#git-errors-after-unshare)
  - [Docker](#docker)
- [TO DO](#to-do)
- [CHANGELOG](#changelog)
- [LICENSE](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Badges

![Build Status](https://github.com/containerscrew/infratools/actions/workflows/build.yml/badge.svg)
![Build Status](https://github.com/containerscrew/infratools/actions/workflows/hadolint.yml/badge.svg)
[![License](https://img.shields.io/github/license/containerscrew/infratools)](/LICENSE)
![Latest Tag](https://img.shields.io/github/v/tag/containerscrew/infratools?sort=semver)

[![DockerHub Badge](http://dockeri.co/image/containerscrew/infratools)](https://hub.docker.com/r/containerscrew/infratools/)


#  About

How many times do you need a container image with tools like `terraform, helm, kubectl, aws cli, terragrunt`... among many others? Aren't you tired of having to maintain all of them in each repository, instead of having one **"general"** one that can be used in multiple repos?

**Available tags:** https://hub.docker.com/repository/docker/containerscrew/infratools/general

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

## Versioning

> Alpine core packages: https://pkgs.alpinelinux.org/packages

> AWS cli v2 is installed directly from official alpine repository. If you need to look for other version, [visit this page](https://pkgs.alpinelinux.org/packages?name=aws-cli&branch=edge&repo=&arch=&maintainer=)

> For every new version, a new git tag will be created. You can see versioning inside [Containerfile](./Containerfile)

## Dynamically change terraform version

> [!TIP]
> By default, a version of terraform is installed using `tfenv`. If you have the `.terraform-version` file in your `terraform/terragrunt` repository, `tfenv` should detect the version and install it automatically.


Or change it yourself, for example, within a pipeline:

```shell
tfenv use 1.5.5
```

# Architecture

| Arch    | Supported | Tested |
|---------|----------|--------|
| amd64   | ✅        | ✅        |
| arm64   | ✅         | ✅         |

# Image security scan with Trivy

This image uses [trivy github action](https://github.com/aquasecurity/trivy-action) as a tool for security scanning.

Take a look to the [official repo](https://github.com/aquasecurity/trivy) of Trivy.

## Local trivy scan

[Install trivy](https://aquasecurity.github.io/trivy/test/getting-started/installation/)

```shell
make build-image # podman build --format docker -t docker.io/containerscrew/infratools:test .
make trivy-scan # trivy image docker.io/containerscrew/infratools:test
```

# Running locally

```shell
podman run --rm -it --name infratools docker.io/containerscrew/infratools:v1.4.2
```

> Use the version([tag](https://github.com/containerscrew/infratools/tags)) you need.

## Rootless (podman)

The container is started as a non-root user. If you map directories, by default the owner:group will be root:root (using podman). Here I leave you a link that explains how to map directories into non-root containers, and be able to write.

* https://www.tutorialworks.com/podman-rootless-volumes/
* https://stackoverflow.com/questions/75817076/no-matter-what-i-do-podman-is-mounting-volumes-as-root


### Mapping volumes with podman unshare

```shell
cd $HOME/mycode
podman unshare chown -R 1000:1000 $HOME/mycode
podman run -it --rm --name infratools -v $HOME/mycode:/code.ssh:Z -w /code  docker.io/containerscrew/infratools:v1.4.2
```

![example](./example.png)

### Git errors after unshare

`fatal: detected dubious ownership in repository at '$HOME/mycode'
To add an exception for this directory, call:`

```git config --global --add safe.directory $HOME/mycode```

## Docker

> [!IMPORTANT]
> I guess with Docker you don't need to do any of this. Honestly I don't use Docker. If there is a problem, open an issue.

# TO DO

* Add also tag `latest` in docker hub images.
* Add other dynamic version switchers for other tools (tgswitch, kubectl...)
* Automatic pipeline cron with image scan & automatic build

# CHANGELOG

Pending to add changelog to track every new git tag is created, which versions are included.

# LICENSE

[LICENSE](./LICENSE)
