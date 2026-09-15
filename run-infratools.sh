#! /usr/bin/env bash

# Configuration
CONTAINER_NAME="$(basename $PWD)"
HOSTNAME="$(whoami)"
CONTAINER_VERSION="3.4.0"
IMAGE_NAME="docker.io/containerscrew/infratools"
REGISTRY_URL="https://registry.hub.docker.com/v2/repositories/containerscrew/infratools/tags?page_size=10"

# Optional aws-vault profile. When set (via -p <profile> or this environment
# variable), the container receives short-lived credentials as environment
# variables instead of a mounted ~/.aws directory.
AWS_VAULT_PROFILE="${AWS_VAULT_PROFILE:-}"

# Function to check prerequisites
check_prerequisites() {
    local required=(curl jq docker)
    if [[ -n "$AWS_VAULT_PROFILE" ]]; then
        required+=(aws-vault)
    fi
    for cmd in "${required[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo -e "\e[31m[ERROR] Required command '$cmd' is not installed.\e[0m"
            exit 1
        fi
    done
}

# Function to fetch the latest version
fetch_latest_version() {
    local latest_version
    latest_version=$(curl -s "$REGISTRY_URL" | jq -r '[.results[].name | select(test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))] | first')
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
    if [[ -n "$AWS_VAULT_PROFILE" ]]; then
        echo "AWS credentials: aws-vault profile ${AWS_VAULT_PROFILE}"
    else
        echo "AWS credentials: mounted ~/.aws"
    fi
    echo "-----------------------------------------------------------"
}

# Function to start the container
start_container() {
    ENV_FILE=".user/env"
    ENV_FILE_OPTION=()

    if [ -f "$ENV_FILE" ]; then
        ENV_FILE_OPTION=(--env-file "$ENV_FILE")
    fi

    # Default: share the host AWS configuration with the container.
    local AWS_OPTIONS=(-v ~/.aws:/home/infratools/.aws)
    local AWS_VAULT_EXEC=()

    if [[ -n "$AWS_VAULT_PROFILE" ]]; then
        # aws-vault exports ephemeral credentials as AWS_* variables, so the
        # container gets temporary keys instead of long-lived config files.
        # A valueless '-e VAR' forwards the variable from the current environment.
        AWS_OPTIONS=(
            -e AWS_ACCESS_KEY_ID
            -e AWS_SECRET_ACCESS_KEY
            -e AWS_SESSION_TOKEN
            -e AWS_SESSION_EXPIRATION
        )
        if [[ -n "$AWS_VAULT" ]]; then
            # Nesting aws-vault fails with "running in an existing aws-vault
            # subshell", so reuse the credentials already in the environment.
            printf "\e[33m[WARNING] Already inside an aws-vault subshell (%s), reusing its credentials instead of profile '%s'.\e[0m\n" "$AWS_VAULT" "$AWS_VAULT_PROFILE"
        else
            AWS_VAULT_EXEC=(aws-vault exec "$AWS_VAULT_PROFILE" --)
            printf "\e[32m[INFO] Using aws-vault profile '%s'\e[0m \n" "$AWS_VAULT_PROFILE"
        fi
    fi

    local CONTAINER_VERSION=${1:-$CONTAINER_LATEST_VERSION}
    printf "\e[32m[INFO] Starting a new container '${CONTAINER_NAME}'...\e[0m \n"
    "${AWS_VAULT_EXEC[@]}" docker run -tid \
        --name "${CONTAINER_NAME}" \
        --rm \
        -h "${HOSTNAME}" \
        -v "$(pwd):/code" \
        -v ~/.ssh:/home/infratools/.ssh \
        -v ~/.kube:/home/infratools/.kube \
        "${AWS_OPTIONS[@]}" \
        "${EXTRA_VOLUMES[@]}" \
        -w /code/ \
        -e AWS_DEFAULT_REGION=eu-west-1 \
        --dns 1.1.1.1 \
        "${ENV_FILE_OPTION[@]}" \
        "${IMAGE_NAME}:${CONTAINER_VERSION}"
}

# Function to attach to the running container
attach_container() {
    printf "\e[32m[INFO] Attaching to the running container '${CONTAINER_NAME}'...\e[0m"
    docker exec -ti "${CONTAINER_NAME}" /bin/zsh
}

# Function to handle updates
update_container() {
    printf "\e[32m[INFO] Updating container '${CONTAINER_NAME}' to the latest version (${LATEST_VERSION})...\e[0m \n"
    docker stop "${CONTAINER_NAME}" &>/dev/null || true
    start_container "${LATEST_VERSION}"
    docker exec -ti "${CONTAINER_NAME}" /bin/zsh
}

usage() {
    printf "\e[32mUsage: $0 [-i (info)] [-u (update)] [-a (attach or create)] [-v <host_path>:<container_path>] [-p <aws-vault profile>]\e[0m\n"
}

# Fetch the current running version
CURRENT_RUNNING_VERSION=$(docker ps --filter "name=^/${CONTAINER_NAME}$" --format '{{.Image}}' | awk -F':' '{print $2}')
if [[ -z "$CURRENT_RUNNING_VERSION" ]]; then
    CURRENT_RUNNING_VERSION="Not running"
fi

# Fetch the latest version
LATEST_VERSION=$(fetch_latest_version)

# First pass: collect configuration options (-v, -p) regardless of the order
# they were given in, so that '-a -v ...' and '-a -p ...' also work.
EXTRA_VOLUMES=()
while getopts "iuav:p:" opt; do
    case "$opt" in
        v)  # Add extra volume
            if [[ "$OPTARG" == *:* ]]; then
                EXTRA_VOLUMES+=("-v" "$OPTARG")
            else
                printf "\e[31m[ERROR] Invalid volume mapping. Use -v <host_path>:<container_path>\e[0m\n"
                exit 1
            fi
            ;;
        p)  # Use an aws-vault profile instead of mounting ~/.aws
            AWS_VAULT_PROFILE="$OPTARG"
            ;;
        i|u|a) ;;  # Actions are handled in the second pass
        *)  # Invalid option
            printf "\e[31m[ERROR] Invalid option.\e[0m\n"
            usage
            exit 1
            ;;
    esac
done

# If no options are provided, show usage
if [[ $OPTIND -eq 1 ]]; then
    usage
    exit 0
fi

# Check prerequisites
check_prerequisites

# Second pass: run the requested actions
OPTIND=1
while getopts "iuav:p:" opt; do
    case "$opt" in
        i)  # Print info
            print_info
            ;;
        u)  # Update the container if necessary
            if [[ "$LATEST_VERSION" != "$CURRENT_RUNNING_VERSION" ]]; then
                update_container
            else
                printf "\e[32m[INFO] The container is already up-to-date.\e[0m"
            fi
            ;;
        a)  # Attach to the container
            if docker ps --filter "name=^/${CONTAINER_NAME}$" --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
                attach_container
            else
                printf "\e[33m[WARNING] No running container found. Starting a new one...\e[0m\n"
                start_container "${CONTAINER_VERSION}"
                attach_container
            fi
            ;;
        v|p) ;;  # Already handled in the first pass
    esac
done
