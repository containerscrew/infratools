ARG ALPINE_VERSION="3.19.1"
FROM docker.io/alpine:${ALPINE_VERSION}

ARG HELM_VERSION=3.13.2
ARG KUBECTL_VERSION=1.26.0
ARG TERRAFORM_VERSION=1.6.4
ARG TERRAGRUNT_VERSION=0.53.8
ARG AWSCLI_VERSION=2.15.14-r0
ENV USERNAME=infratools
ENV USER_UID=1000
ENV USER_GID=$USER_UID

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
    make ca-certificates bash jq zip shadow curl git

# AWS CLI
RUN apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community aws-cli=${AWSCLI_VERSION}

# Helm
RUN source /envfile && curl -sL https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz | tar -xz ;\
    mv linux-${ARCH}/helm /usr/bin/helm ;\
    chmod +x /usr/bin/helm ;\
    rm -rf linux-${ARCH}

# Kubectl
RUN source /envfile && curl -sL https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

# Terraform
RUN source /envfile && curl -sL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip -o terraform.zip ;\
    unzip -q terraform.zip ;\
    mv terraform /usr/bin ;\
    rm terraform.zip

# Terragrunt
RUN source /envfile && curl -sL https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_${ARCH} -o /usr/bin/terragrunt ;\
    chmod +x /usr/bin/terragrunt

# Install tftools
RUN curl --proto '=https' --tlsv1.2 -sSfL https://raw.githubusercontent.com/containerscrew/tftools/main/scripts/install.sh | bash

RUN groupadd --gid $USER_GID $USERNAME ;\
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash

USER $USERNAME
WORKDIR /home/$USERNAME
COPY .bashrc .bashrc
ENTRYPOINT ["/bin/bash"]