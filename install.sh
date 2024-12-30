#!/bin/bash

echo -e "
    ____                           __     ___                __           _     
   /  _/___ ___  ____  ____ ______/ /_   /   |  ____  ____ _/ /_  _______(_)____
   / // __ \`__ \/ __ \/ __ \`/ ___/ __/  / /| | / __ \/ __ \`/ / / / / ___/ / ___/
 _/ // / / / / / /_/ / /_/ / /__/ /_   / ___ |/ / / / /_/ / / /_/ (__  ) (__  ) 
/___/_/ /_/ /_/ .___/\__,_/\___/\__/  /_/  |_/_/ /_/\__,_/_/\__, /____/_/____/  Install script    
             /_/                                           /____/       
####              
"

# Function to check if Docker is installed and running
check_docker() {
    if ! docker -v &> /dev/null; then
        echo "Docker is not installed or not in PATH. Please install Docker to proceed."
        exit 1
    fi
}

CONFIG_FILE="./config.json"

# Function to generate credentials
create_config_json() {
    echo -n "Enter your GitHub registry token: "
    read -s GITHUB_TOKEN
    echo

    ENCODED_AUTH=$(echo -n "username:${GITHUB_TOKEN}" | base64)

    # Crea il file config.json
    cat > "$CONFIG_FILE" <<EOF
{
    "auths": {
        "ghcr.io": {
            "auth": "${ENCODED_AUTH}"
        }
    }
}
EOF
    echo "A new config.json has been created."
}

# Function to configure the installation
configure_installation() {
    echo "Select the installation type:"
    echo "1) Express"
    echo "2) Custom"
    read -p "Choice [1/2]: " INSTALL_TYPE

    case $INSTALL_TYPE in
        1)
            VERSION="stable"
            PROTOCOL="https"
            WATCHTOWER=true
            REPO_PATH="."
            read -p "Enter IP of your machine: " IP
            ;;
        2)
            echo "Select the version (stable/snapshot):"
            read -p "Choice: " VERSION
            echo "Select the protocol (https/http):"
            read -p "Choice: " PROTOCOL
            echo "Enable auto-updater (watchtower)? [true/false]:"
            read -p "Choice: " WATCHTOWER
            echo "Path of repositories directory:"
            read -p "Choice: " REPO_PATH
            read -p "Enter the IP of your machine: " IP
            ;;
        *)
            echo "Invalid choice."
            configure_installation
            ;;
    esac

    echo
    echo "Configuration summary:"
    echo "Version: $VERSION"
    echo "Protocol: $PROTOCOL"
    echo "Auto-updater: $WATCHTOWER"
    echo "Public IP: $IP"
    echo "Repositories directory : $REPO_PATH"
    echo
    read -p "Confirm? [y/n]: " CONFIRM
    if [[ "$CONFIRM" != "y" ]]; then
        configure_installation
    fi
}

env_generation() {
    BASE_ENV_FILE="./.base.env"
    ENV_FILE="./.env"

    # check if .base.env exists
    if [ ! -f "$BASE_ENV_FILE" ]; then
        echo "Error: $BASE_ENV_FILE not found."
        exit 1
    fi

    
    cp "$BASE_ENV_FILE" "$ENV_FILE"

    # update variables
    sed -i "s/^CORE_TAG=.*/CORE_TAG=${VERSION}/" "$ENV_FILE"
    sed -i "s/^PREDICTION_TAG=.*/PREDICTION_TAG=${VERSION}/" "$ENV_FILE"
    sed -i "s/^MINER_SCHEDULER_TAG=.*/MINER_SCHEDULER_TAG=${VERSION}/" "$ENV_FILE"
    sed -i "s/^MINER_API_TAG=.*/MINER_API_TAG=${VERSION}/" "$ENV_FILE"
    sed -i "s/^DASHBOARD_TAG=.*/DASHBOARD_TAG=${VERSION}/" "$ENV_FILE"
    sed -i "s/^USER_VOLUME=.*/USER_VOLUME=${REPO_PATH}/" "$ENV_FILE"
    if $WATCHTOWER; then
        sed -i "s/^ENABLE_WATCHTOWER=.*/ENABLE_WATCHTOWER=1/" "$ENV_FILE"
    else
        sed -i "s/^ENABLE_WATCHTOWER=.*/ENABLE_WATCHTOWER=0/" "$ENV_FILE"
    fi
    if [[ "$PROTOCOL" != "https" ]]; then
        sed -i "s/^CORE_AUTHCOOKIE_SECURE=.*/ENABLE_WATCHTOWER=false/" "$ENV_FILE"
    else
        sed -i "s/^CORE_AUTHCOOKIE_SECURE=.*/ENABLE_WATCHTOWER=true/" "$ENV_FILE"
    fi

}


# Script start
echo "This script will install the application using Docker."
echo "Make sure you have Docker installed and running."
read -p "Do you want to proceed? [y/n]: " PROCEED
if [[ "$PROCEED" != "y" ]]; then
    echo "Installation canceled."
    exit 0
fi

# Check Docker
check_docker

# Log in to GitHub Registry
if [ -f "$CONFIG_FILE" ]; then
    echo "A config.json file was found. Using existing credentials."
    echo "If you wish to logout simply delete the config.json file"
else
    echo "No config.json file found. Creating a new one..."
    create_config_json
fi

# Configure installation
configure_installation

env_generation

# TODO: runtime generation

docker compose run watchtower --run-once

#TODO: pull via watchtower

# Finalization
echo "Installation completed!"
echo "To start the application, run: docker compose up"
