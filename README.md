<p align="center" >
    <img src="logo.png" alt="logo" width="250"/>
<h3 align="center">infratools</h3>
<p align="center">Container image with infra tools (terraform, terragrunt, aws cli, helm, kubectl...). Useful for CI/CD.</p>
</p>

# Badges

![Build Status](https://github.com/containerscrew/infratools/actions/workflows/build.yml/badge.svg)
![Build Status](https://github.com/containerscrew/infratools/actions/workflows/hadolint.yml/badge.svg)
[![License](https://img.shields.io/github/license/containerscrew/infratools)](/LICENSE)  

[![DockerHub Badge](http://dockeri.co/image/containerscrew/infratools)](https://hub.docker.com/r/containerscrew/infratools/)


#  About

How many times do you need a container image with tools like `terraform, helm, kubectl, aws cli, terragrunt`... among many others? Aren't you tired of having to maintain all of them in each repository, instead of having one **"general"** one that can be used in multiple repos?

**Available tags:** https://hub.docker.com/repository/docker/containerscrew/infratools/general 

# Architecture

| Arch    | Supported | Tested |
|---------|----------|--------|
| amd64   | ✅        | ✅        |
| arm64   | ✅         | ✅         |


# Available tools

| Tool       | Available |
|------------|----------|
| Terraform  |   ✅      |
| Terragrunt |   ✅      |
| Kubectl    |   ✅      |
| Helm       |   ✅      |
| AWS CLI    |   ✅      |

> AWS cli v2 is installed directly from official alpine repository. If you need to look for other version, [visit this page](https://pkgs.alpinelinux.org/packages?name=aws-cli&branch=edge&repo=&arch=&maintainer=)

> For every new version, a new git tag will be created. You can see versioning inside [Containerfile](./Containerfile)

# Running locally

```shell
podman run --rm -it --name infratools docker.io/containerscrew/infratools:v1.0.0 # use the version you need
```

# LICENSE

[LICENSE](./LICENSE)