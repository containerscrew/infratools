#!/bin/bash

# Configuration
CONTAINER_NAME="infratools"
CONTAINER_VERSION="v2.7.1"
IMAGE_NAME="docker.io/containerscrew/infratools"
REGISTRY_URL="https://registry.hub.docker.com/v2/repositories/containerscrew/infratools/tags?page_size=1"

# Function to check prerequisites
check_prerequisites() {
    for cmd in curl jq docker; do
        if ! command -v "$cmd" &>/dev/null; then
            echo -e "\e[31m[ERROR] Required command '$cmd' is not installed.\e[0m"
            exit 1
        fi
    done
}

# Function to fetch the latest version
fetch_latest_version() {
    local latest_version
    latest_version=$(curl -s "$REGISTRY_URL" | jq -r '.results[0].name')
    if [[ $? -ne 0 || -z "$latest_version" ]]; then
        echo -e "\e[31m[ERROR] Failed to fetch the latest version. Check your internet connection or 'jq' installation.\e[0m"
        echo "Unknown"
    else
        echo "$latest_version"
    fi
}

# Function to print container info
print_info() {
    echo -e "\e[32m[INFO] Current Configuration and Container Status:\e[0m"
    echo "-----------------------------------------------------------"
    echo "Configured version: ${CONTAINER_VERSION}"
    echo "Running version: ${CURRENT_RUNNING_VERSION}"
    echo "Latest version: ${LATEST_VERSION}"
    echo "-----------------------------------------------------------"
}

# Function to start the container
start_container() {
    echo -e "\e[32m[INFO] Starting a new container '${CONTAINER_NAME}'...\e[0m"
    docker run -tid \
        --name "${CONTAINER_NAME}" \
        --rm \
        -h "${CONTAINER_NAME}" \
        -v "$(pwd):/code" \
        -v ~/.ssh:/home/infratools/.ssh \
        -v ~/.aws:/home/infratools/.aws \
        -v ~/.kube:/home/infratools/.kube \
        -w /code/ \
        -e AWS_DEFAULT_REGION=eu-west-1 \
        --dns 1.1.1.1 \
        "${IMAGE_NAME}:${CONTAINER_VERSION}"
}

# Function to attach to the running container
attach_container() {
    echo -e "\e[32m[INFO] Attaching to the running container '${CONTAINER_NAME}'...\e[0m"
    docker exec -ti "${CONTAINER_NAME}" zsh
}

# Function to handle updates
update_container() {
    echo -e "\e[32m[INFO] Updating container '${CONTAINER_NAME}' to the latest version (${LATEST_VERSION})...\e[0m"
    docker stop "${CONTAINER_NAME}" &>/dev/null || true
    start_container
}

# Fetch the current running version
CURRENT_RUNNING_VERSION=$(docker ps --filter "name=^/${CONTAINER_NAME}$" --format '{{.Image}}' | awk -F':' '{print $2}')
if [[ -z "$CURRENT_RUNNING_VERSION" ]]; then
    CURRENT_RUNNING_VERSION="Not running (first time)"
fi

# Fetch the latest version
LATEST_VERSION=$(fetch_latest_version)

# Check prerequisites
check_prerequisites

# Parse options with getopts
while getopts "iua" opt; do
    case "$opt" in
        i)  # Print info
            print_info
            ;;
        u)  # Update the container if necessary
            if [[ "$LATEST_VERSION" != "$CURRENT_RUNNING_VERSION" ]]; then
                update_container
            else
                echo -e "\e[32m[INFO] The container is already up-to-date.\e[0m"
            fi
            ;;
        a)  # Attach to the container
            if docker ps --filter "name=^/${CONTAINER_NAME}$" --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
                attach_container
            else
                echo -e "\e[33m[WARNING] No running container found. Starting a new one...\e[0m"
                start_container
                attach_container
            fi
            ;;
        *)  # Invalid option
            echo -e "\e[31m[ERROR] Invalid option. Use -i (info), -u (update), or -a (attach or create).\e[0m"
            exit 1
            ;;
    esac
done

# If no options are provided, show usage
if [[ $OPTIND -eq 1 ]]; then
    echo -e "\e[32mUsage: $0 [-i (info)] [-u (update)] [-a (attach or create)]\e[0m"
fi
