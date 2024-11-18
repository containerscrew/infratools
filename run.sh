#!/bin/bash

CONTAINER_NAME="infratools"
CONTAINER_VERSION="v2.6.0"

# Fetch latest image version (tag)
LATEST_VERSION=$(curl -s "https://registry.hub.docker.com/v2/repositories/containerscrew/infratools/tags?page_size=1" | jq -r '.results[0].name')

if [[ $? -ne 0 || -z "$LATEST_VERSION" ]]; then
    echo -e "\e[31mError fetching the latest container version. Please ensure you have Internet access and that 'jq' is installed.\e[0m"
fi

if [[ "$CONTAINER_VERSION" != "$LATEST_VERSION" ]]; then
    echo -e "\e[33m"
    echo "###########################################################"
    echo "---> Warning: The configured version (${CONTAINER_VERSION}) does not match the latest available version (${LATEST_VERSION})"
    echo "---> Warning: Delete the current container and run again the script to pull the latest version"
    echo "###########################################################"
    echo -e "\e[0m"
fi

if [ $(docker ps --filter "name=^/${CONTAINER_NAME}$" --format '{{.Names}}' | wc -l) -gt 0 ]; then
    docker exec -ti ${CONTAINER_NAME} zsh
else
    docker run -tid \
        --name ${CONTAINER_NAME} \
        --rm \
        -h ${CONTAINER_NAME} \
        -v "$(pwd)"/:/code \
        -v ~/.ssh:/home/infratools/.ssh \
        -v ~/.aws:/home/infratools/.aws \
        -v ~/.kube:/home/infratools/.kube \
        -w /code/ \
        -e AWS_DEFAULT_REGION=eu-west-1 \
        --dns 1.1.1.1 \
        docker.io/containerscrew/infratools:${CONTAINER_VERSION}
fi

docker exec -ti "${CONTAINER_NAME}" zsh
