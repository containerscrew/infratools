#  About

How many times do you need a container image with tools like `terraform, helm, kubectl, aws cli, python, terragrunt, openssl`... among many others? Aren't you tired of having to maintain all of them in each repository, instead of having one **"general"** one that can be used in multiple repos?

# Architecture

| Arch    | Supported |
|---------|----------|
| amd64   | ✅        |
| arm64   | ❌         |


# Available tools

| Tool       | Available |
|------------|----------|
| Terraform  |   ✅      |
| Terragrunt |   ✅      |
| Kubectl    |   ✅      |
| Helm       |   ✅      |
| AWS CLI    |   ✅      |

> AWS cli v2 is installed directly from official alpine repository. If you need to look for other version, visit: https://pkgs.alpinelinux.org/packages?name=aws-cli&branch=edge&repo=&arch=&maintainer=