ARG ALPINE_VERSION="3.20.2"
FROM docker.io/alpine:${ALPINE_VERSION}

ARG HELM_VERSION=3.13.2
ARG KUBECTL_VERSION=1.26.0
ARG TERRAFORM_VERSION=1.9.5
ARG TERRAGRUNT_VERSION=0.67.6
ARG AWSCLI_VERSION="2.15.57-r0"
ARG TFTOOLS_VERSION="v0.9.0"
ARG TFLINT_VERSION="0.51.1-r3"
ARG HELM_DOCS_VERSION="1.14.2"
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

# Core packages
RUN apk add --update --no-cache \
    make ca-certificates zsh zsh-vcs jq zip shadow curl git vim bind-tools python3 py3-pip pipx kubectx \
    openssl envsubst aws-cli=${AWSCLI_VERSION} docker-cli fzf bash fzf openssh-client-krb5 tflint=${TFLINT_VERSION} \
    pre-commit

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

# Terraform using tfenv
RUN git clone --depth=1 https://github.com/tfutils/tfenv.git $USER_HOME/.tfenv ;\
    ln -s $USER_HOME/.tfenv/bin/* /usr/local/bin ;\
    TFENV_ARCH="amd64" tfenv use ${TERRAFORM_VERSION} ;\
    chown -R $USERNAME:$USERNAME $USER_HOME/.tfenv/

# Terragrunt
RUN source /envfile && curl -sL https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_${ARCH} -o /usr/bin/terragrunt ;\
    chmod +x /usr/bin/terragrunt

# Install tftools
RUN curl --proto '=https' --tlsv1.2 -sSfL https://raw.githubusercontent.com/containerscrew/tftools/main/scripts/install.sh | sh -s -- -v "$TFTOOLS_VERSION"

# Install helm-docs plugin
# RUN source /envfile && curl -sL https://github.com/norwoodj/helm-docs/releases/download/v${HELM_DOCS_VERSION}/helm-docs_${HELM_DOCS_VERSION}_Linux_${ALT_ARCH}.tar.gz -o /tmp/helm-docs.tar.gz && \
#     tar -xz -C /usr/bin/ -f /tmp/helm-docs.tar.gz helm-docs && \
#     chmod +x /usr/bin/helm-docs && \
#     rm /tmp/helm-docs.tar.gz

# User actions
USER $USERNAME

# Install oh my zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

WORKDIR $USER_HOME

COPY .zshrc .zshrc
