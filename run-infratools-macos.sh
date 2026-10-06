#! /usr/bin/env bash

# macOS variant of run-infratools.sh using Apple's native `container` CLI
# (https://github.com/apple/container, macOS 26+, Apple silicon) instead of podman/docker.
#
# Optional environment variables:
#   INFRATOOLS_PLATFORM=linux/amd64      Force image platform (default: native arch).
#                                        amd64 on Apple silicon also enables Rosetta.

# Configuration
CONTAINER_NAME="$(basename "$PWD")"
CONTAINER_VERSION="3.5.0"
IMAGE_NAME="docker.io/containerscrew/infratools"
REGISTRY_URL="https://registry.hub.docker.com/v2/repositories/containerscrew/infratools/tags?page_size=10"
PLATFORM="${INFRATOOLS_PLATFORM:-}"

# Function to check prerequisites
check_prerequisites() {
    for cmd in curl jq container; do
        if ! command -v "$cmd" &>/dev/null; then
            printf "\e[31m[ERROR] Required command '%s' is not installed.\e[0m\n" "$cmd"
            exit 1
        fi
    done
}

# Function to make sure the container system service is up (first run prompts for kernel install)
ensure_system_running() {
    if ! container system status &>/dev/null; then
        printf "\e[33m[WARNING] container system service is not running. Starting it...\e[0m\n"
        container system start || exit 1
    fi
}

# Function to fetch the latest version
fetch_latest_version() {
    local latest_version
    latest_version=$(curl -s "$REGISTRY_URL" | jq -r '[.results[].name | select(test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))] | first')
    if [[ $? -ne 0 || -z "$latest_version" || "$latest_version" == "null" ]]; then
        printf "\e[31m[ERROR] Failed to fetch the latest version. Check your internet connection or 'jq' installation.\e[0m\n" >&2
        echo "Unknown"
    else
        echo "$latest_version"
    fi
}

# Function to get the image reference of the running container (empty if not running)
running_image() {
    container list --format json 2>/dev/null | jq -r --arg name "$CONTAINER_NAME" \
        '.[] | select((.configuration.id // .id) == $name) | (.configuration.image.reference // .image.reference // empty)'
}

# Function to print container info
print_info() {
    printf "\e[32m[INFO] Current Configuration and Container Status:\e[0m\n"
    echo "-----------------------------------------------------------"
    echo "Configured version: ${CONTAINER_VERSION}"
    echo "Running version: ${CURRENT_RUNNING_VERSION}"
    echo "Latest version: ${LATEST_VERSION}"
    echo "-----------------------------------------------------------"
}

# Function to start the container
start_container() {
    ENV_FILE=".user/env"
    ENV_FILE_OPTION=()
    PLATFORM_OPTION=()

    if [ -f "$ENV_FILE" ]; then
        ENV_FILE_OPTION=(--env-file "$ENV_FILE")
    fi

    if [ -n "$PLATFORM" ]; then
        PLATFORM_OPTION=(--platform "$PLATFORM")
        [[ "$PLATFORM" == *amd64* ]] && PLATFORM_OPTION+=(--rosetta)
    fi

    local CONTAINER_VERSION=${1:-$CONTAINER_VERSION}
    printf "\e[32m[INFO] Starting a new container '%s'...\e[0m \n" "${CONTAINER_NAME}"
    container run -t -i -d \
        --name "${CONTAINER_NAME}" \
        --rm \
        -v "$(pwd):/code" \
        -v ~/.ssh:/home/infratools/.ssh \
        -v ~/.aws:/home/infratools/.aws \
        -v ~/.kube:/home/infratools/.kube \
        ${EXTRA_VOLUMES[@]+"${EXTRA_VOLUMES[@]}"} \
        -w /code/ \
        -e AWS_DEFAULT_REGION=eu-west-1 \
        --dns 1.1.1.1 \
        ${PLATFORM_OPTION[@]+"${PLATFORM_OPTION[@]}"} \
        ${ENV_FILE_OPTION[@]+"${ENV_FILE_OPTION[@]}"} \
        "${IMAGE_NAME}:${CONTAINER_VERSION}"
}

# Function to attach to the running container
attach_container() {
    printf "\e[32m[INFO] Attaching to the running container '%s'...\e[0m\n" "${CONTAINER_NAME}"
    container exec -t -i "${CONTAINER_NAME}" /bin/zsh
}

# Function to handle updates
update_container() {
    printf "\e[32m[INFO] Updating container '%s' to the latest version (%s)...\e[0m \n" "${CONTAINER_NAME}" "${LATEST_VERSION}"
    container stop "${CONTAINER_NAME}" &>/dev/null || true
    start_container "${LATEST_VERSION}"
    container exec -t -i "${CONTAINER_NAME}" /bin/zsh
}

# Check prerequisites and make sure the container service is up
check_prerequisites
ensure_system_running

# Fetch the current running version
CURRENT_RUNNING_IMAGE=$(running_image)
CURRENT_RUNNING_VERSION="${CURRENT_RUNNING_IMAGE##*:}"
if [[ -z "$CURRENT_RUNNING_IMAGE" ]]; then
    CURRENT_RUNNING_VERSION="Not running"
fi

# Fetch the latest version
LATEST_VERSION=$(fetch_latest_version)

# Parse options with getopts, including -v for extra volumes
EXTRA_VOLUMES=()
while getopts "iuav:" opt; do
    case "$opt" in
        i)  # Print info
            print_info
            ;;
        u)  # Update the container if necessary
            if [[ "$LATEST_VERSION" != "$CURRENT_RUNNING_VERSION" ]]; then
                update_container
            else
                printf "\e[32m[INFO] The container is already up-to-date.\e[0m\n"
            fi
            ;;
        a)  # Attach to the container
            if [[ -n "$CURRENT_RUNNING_IMAGE" ]]; then
                attach_container
            else
                printf "\e[33m[WARNING] No running container found. Starting a new one...\e[0m\n"
                start_container "${CONTAINER_VERSION}"
                attach_container
            fi
            ;;
        v)  # Add extra volume
            if [[ "$OPTARG" == *:* ]]; then
                EXTRA_VOLUMES+=("-v" "$OPTARG")
            else
                printf "\e[31m[ERROR] Invalid volume mapping. Use -v <host_path>:<container_path>\e[0m\n"
                exit 1
            fi
            ;;
        *)  # Invalid option
            printf "\e[31m[ERROR] Invalid option. Use -i (info), -u (update), -a (attach), or -v <host_path>:<container_path>.\e[0m\n"
            exit 1
            ;;
    esac
done

# If no options are provided, show usage
if [[ $OPTIND -eq 1 ]]; then
    printf "\e[32mUsage: %s [-i (info)] [-u (update)] [-a (attach or create)] [-v <host_path>:<container_path>]\e[0m\n" "$0"
fi
