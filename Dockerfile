# hadolint global ignore=DL3018,DL4006
ARG ALPINE_VERSION="3.23"

# Base stage: shared arch detection
FROM docker.io/alpine:${ALPINE_VERSION} AS base

RUN set -eux

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

# CI stage: lightweight image for deploy pipelines (kubectl, helm, aws, jq, curl)
FROM base AS ci

ARG HELM_VERSION=4.1.4
ARG KUBECTL_VERSION=1.36.1
ARG AWSCLI_VERSION="2.32.7-r0"
ENV USERNAME="ci"
ENV USER_UID=1000
ENV USER_GID=1000
ENV USER_HOME="/home/ci"

RUN apk upgrade --no-cache && \
    apk add --no-cache \
    ca-certificates curl jq aws-cli=${AWSCLI_VERSION}

RUN addgroup -g $USER_GID $USERNAME && \
    adduser -u $USER_UID -G $USERNAME -h $USER_HOME -s /bin/sh -D $USERNAME

RUN . /envfile && curl -sL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz" | tar -xz ;\
    mv "linux-${ARCH}/helm" /usr/bin/helm ;\
    chmod +x /usr/bin/helm ;\
    rm -rf "linux-${ARCH}"

RUN . /envfile && \
    curl -sLO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

USER $USERNAME
WORKDIR $USER_HOME

# Full stage: complete local toolbox (tofu, terragrunt, zsh, krew...)
FROM base AS full

ARG HELM_VERSION=4.1.4
ARG KUBECTL_VERSION=1.35.5
ARG TOFU_VERSION=v1.11.7
ARG TERRAGRUNT_VERSION=1.0.4
ARG AWSCLI_VERSION="2.32.7-r0"
ENV USERNAME="infratools"
ENV USER_UID=1000
ENV USER_GID=1000
ENV USER_HOME="/home/infratools"
ENV PYTHONUNBUFFERED=1
ENV PATH="${PATH}:${USER_HOME}/.local/bin:${USER_HOME}/.krew/bin"

RUN apk upgrade --no-cache && \
    apk add --no-cache \
    make ca-certificates zsh zsh-vcs jq zip shadow curl git vim bind-tools kubectx \
    openssl envsubst aws-cli=${AWSCLI_VERSION} docker-cli fzf bash fzf openssh-client-krb5 \
    pre-commit

RUN groupadd --gid $USER_GID $USERNAME ;\
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/zsh

# Helm
RUN . /envfile && curl -sL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz" | tar -xz ;\
    mv "linux-${ARCH}/helm" /usr/bin/helm ;\
    chmod +x /usr/bin/helm ;\
    rm -rf "linux-${ARCH}"

# Kubectl
RUN . /envfile && \
    curl -sLO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# Opentofu
RUN . /envfile && \
    curl -sL -o /tmp/tofu.apk "https://github.com/opentofu/opentofu/releases/download/${TOFU_VERSION}/tofu_${TOFU_VERSION#v}_${ARCH}.apk" && \
    apk add --no-cache --allow-untrusted /tmp/tofu.apk && \
    rm -f /tmp/tofu.apk && \
    tofu --version

# Install tfenv for terraform compatibility
RUN git clone --depth=1 https://github.com/tfutils/tfenv.git $USER_HOME/.tfenv ;\
    ln -s $USER_HOME/.tfenv/bin/* /usr/local/bin ;\
    chown -R $USERNAME:$USERNAME $USER_HOME/.tfenv/

# Terragrunt
RUN . /envfile && curl -sL "https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_${ARCH}" -o /usr/bin/terragrunt ;\
    chmod +x /usr/bin/terragrunt

USER $USERNAME

# Install krew
# hadolint ignore=DL3003
RUN set -x; cd "$(mktemp -d)" && \
    OS="$(uname | tr '[:upper:]' '[:lower:]')" && \
    ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" && \
    KREW="krew-${OS}_${ARCH}" && \
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" && \
    tar zxvf "${KREW}.tar.gz" && \
    ./"${KREW}" install krew && \
    rm -rf ./*

# Install kubelogin
RUN set -x; export PATH="${PATH}:${USER_HOME}/.krew/bin" && kubectl krew install oidc-login

# Install oh my zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

WORKDIR $USER_HOME

COPY .zshrc .zshrc
