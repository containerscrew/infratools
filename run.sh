#!/bin/bash

CONTAINER_NAME="infratools"
CONTAINER_VERSION="v2.3.0"

if [ $(docker ps | grep ${CONTAINER_NAME} | wc -l) -gt 0 ];then
    docker exec -ti ${CONTAINER_NAME} zsh
else
    docker run -tid \
        --name ${CONTAINER_NAME} \
        --rm \
        -h ${CONTAINER_NAME} \
        -v $(pwd)/:/code \
        -v ~/.ssh:/home/infratools/.ssh \
        -v ~/.aws:/home/infratools/.aws \
        -v ~/.kube:/home/infratools/.kube \
        -v ~/.zsh_history/:/home/infratools/.zsh_history \
        -w /code/ \
        -e AWS_DEFAULT_REGION=eu-west-1 \
#        --dns 1.1.1.1 \
        docker.io/containerscrew/infratools:${CONTAINER_VERSION}
    docker exec -it ${CONTAINER_NAME} zsh
fi