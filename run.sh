#!/bin/bash

CONTAINER_NAME="infratools"
CONTAINER_VERSION="v2.5.2"

if [ "$(docker ps | grep -c "${CONTAINER_NAME}")" -gt 0 ];then
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
