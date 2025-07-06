<p align="center" >
    <img src="logo.png" alt="logo" width="250"/>
<h3 align="center">infratools</h3>
<p align="center">Container image with infra tools (tofu, terragrunt, aws cli, helm, kubectl...). Useful for CI/CD or local deployments.</p>
</p>

---

<p align="left">
  <strong>&gt; <a href="https://hub.docker.com/r/containerscrew/infratools/tags">Available tags</a></strong><br>
  <strong>&gt; Latest tag:</strong> <img src="https://img.shields.io/github/v/tag/containerscrew/infratools?sort=semver">
</p>

[![DockerHub Badge](http://dockeri.co/image/containerscrew/infratools)](https://hub.docker.com/r/containerscrew/infratools/)

---

# Architecture

| Arch    | Supported | Tested |
|---------|----------|--------|
| amd64   | ✅        | ✅        |
| arm64   | ✅         | ✅         |

# Usage

Create a copy of the script [`run-infratools.sh`](run-infratools.sh) in your repository and run it.

```shell
/run-infratools.sh
Usage: /usr/local/bin/run-infratools.sh [-i (info)] [-u (update)] [-a (attach or create)] [-v <host_path>:<container_path>]
```

Mapping volumes:

```shell
run-infratools.sh -a -v ~/.lacework.toml:/home/infratools/.lacework.toml
```

Move this script to your bin path, and reuse it in other repos:

```shell
sudo cp run-infratools.sh /usr/local/bin/
```

With this script, you can run the container or attach to an existing, update the container to the latest tag version, or get the current version of the container.

> [!IMPORTANT]
> Running this script, ZSH history will be saved in /code repository to allow persistent command history.
> So, If you don't want to push the .zsh_history to git, add the file to `.gitignore` in the repo you are using.

Run the container directly, without mapping directories:

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

# LICENSE

`infratools` is distributed under the terms of the [`Apache 2.0`](./LICENSE) license.
