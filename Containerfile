ARG ALPINE_VERSION="3.19.1"
FROM docker.io/alpine:${ALPINE_VERSION}

ARG HELM_VERSION=3.13.2
ARG KUBECTL_VERSION=1.26.0
ARG TERRAFORM_VERSION=1.8.1
ARG TERRAGRUNT_VERSION=0.57.5
ARG AWSCLI_VERSION="2.13.25-r0"
ARG TFTOOLS_VERSION="v0.9.0"
ENV USERNAME="infratools"
ENV USER_UID=1000
ENV USER_GID=$USER_UID
ENV USER_HOME="/home/infratools"
ENV PYTHONUNBUFFERED=1

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
    make ca-certificates bash jq zip shadow curl git vim bind-tools python3 py3-pip \
    openssl envsubst aws-cli=${AWSCLI_VERSION}

# Rootless user
RUN groupadd --gid $USER_GID $USERNAME ;\
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash

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
    tfenv use ${TERRAFORM_VERSION} ;\
    chown -R $USERNAME:$USERNAME $USER_HOME/.tfenv/

# Terragrunt
RUN source /envfile && curl -sL https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_${ARCH} -o /usr/bin/terragrunt ;\
    chmod +x /usr/bin/terragrunt

# Install tftools
RUN curl --proto '=https' --tlsv1.2 -sSfL https://raw.githubusercontent.com/containerscrew/tftools/main/scripts/install.sh | sh -s -- -v "$TFTOOLS_VERSION"

USER $USERNAME
WORKDIR $USER_HOME
COPY .bashrc .bashrc
# If using custom binaries
#COPY bin/* /usr/local/bin
ENTRYPOINT ["/bin/bash"]
