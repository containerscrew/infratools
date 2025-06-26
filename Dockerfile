ARG ALPINE_VERSION="3.22.0"
FROM docker.io/alpine:${ALPINE_VERSION}

ARG HELM_VERSION="3.18.3"
ARG KUBECTL_VERSION="1.32.0"
ARG TERRAFORM_VERSION="1.9.5"
ARG TERRAGRUNT_VERSION="0.82.0"
ARG AWSCLI_VERSION="2.27.25-r0"
ARG TFTOOLS_VERSION="v0.9.0"
ENV USERNAME="infratools"
ENV USER_UID=1000
ENV USER_GID=$USER_UID
ENV USER_HOME="/home/infratools"
ENV PYTHONUNBUFFERED=1
ENV PATH="${PATH}:${USER_HOME}/.local/bin"

# Debug (-x), exit on failure (-e) or variable not declared (-u)
RUN set -eux

# hadolint ignore=DL3018
# hadolint global ignore=DL3018,DL4006

# Set architecture
RUN case $(uname -m) in \
    x86_64) ARCH=amd64; ;; \
    armv7l) ARCH=arm; ;; \
    aarch64) ARCH=arm64; ;; \
    ppc64le) ARCH=ppc64le; ;; \
    s390x) ARCH=s390x; ;; \
    *) echo "un-supported arch, exit ..."; exit 1; ;; \
    esac && \
    echo "export ARCH=$ARCH" > /envfile && \
    cat /envfile

# Add testing repository
RUN echo '@community https://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories

# Core packages
RUN apk add --update --no-cache \
    make ca-certificates zsh zsh-vcs jq zip shadow curl git vim bind-tools python3 py3-pip pipx kubectx \
    openssl envsubst aws-cli=${AWSCLI_VERSION} docker-cli fzf bash fzf openssh-client-krb5 \
    pre-commit opentofu@community

# Rootless user
RUN groupadd --gid $USER_GID $USERNAME ;\
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/zsh

# Helm
RUN source /envfile && curl -sL https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz | tar -xz ;\
    mv linux-${ARCH}/helm /usr/bin/helm ;\
    chmod +x /usr/bin/helm ;\
    rm -rf linux-${ARCH}

# Kubectl
RUN source /envfile && curl -sL https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

# Install tfenv for terraform compatibility
RUN git clone --depth=1 https://github.com/tfutils/tfenv.git $USER_HOME/.tfenv ;\
    ln -s $USER_HOME/.tfenv/bin/* /usr/local/bin

# Terragrunt
RUN source /envfile && curl -sL https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_${ARCH} -o /usr/bin/terragrunt ;\
    chmod +x /usr/bin/terragrunt

# Install tftools
RUN curl --proto '=https' --tlsv1.2 -sSfL https://raw.githubusercontent.com/containerscrew/tftools/main/scripts/install.sh | sh -s -- -v "$TFTOOLS_VERSION"

# User actions
USER $USERNAME

# Install oh my zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

WORKDIR $USER_HOME

COPY .zshrc .zshrc
