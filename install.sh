#!/bin/bash

set -e

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
    if ! docker -v &>/dev/null; then
        echo "Docker is not installed or not in PATH. Please install Docker to proceed."
        exit 1
    fi
}

CONFIG_FILE="./docker-conf/config.json"

# Function to generate credentials
create_config_json() {
    echo -n "Enter your GitHub registry token: "
    read -s GITHUB_TOKEN
    echo

    ENCODED_AUTH=$(echo -n "username:${GITHUB_TOKEN}" | base64)

    # Crea il file config.json
    cat >"$CONFIG_FILE" <<EOF
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
        VERSION="latest"
        PROTOCOL="http"
        WATCHTOWER=true
        USER_VOLUME="./repos"
        IP="localhost"
        ;;
    2)
        echo "Select the version (latest/snapshot):"
        read -p "Choice: " VERSION
        echo "Select the protocol (https/http):"
        read -p "Choice: " PROTOCOL
        echo "Enable auto-updater (watchtower)? [true/false]:"
        read -p "Choice: " WATCHTOWER
        echo "Path of repositories directory (default ./repos):"
        read -p "Choice: " USER_VOLUME
        read -p "Public IP or domain of your machine (or localhost): " IP
        ;;
    *)
        echo "Invalid choice."
        configure_installation
        ;;
    esac

    echo
    echo "Configuration summary"
    echo "                Version: $VERSION"
    echo "               Protocol: $PROTOCOL"
    echo "           Auto-updater: $WATCHTOWER"
    echo "              Public IP: $IP"
    echo " Repositories directory: $USER_VOLUME"
    echo
    read -p "Confirm? [y/n]: " CONFIRM
    if [[ "$CONFIRM" != "y" ]]; then
        configure_installation
    fi
}

env_generation() {
    BASE_ENV_FILE="./.base.env"
    ENV_FILE="./.env"

    if [ ! -f "$BASE_ENV_FILE" ]; then
        echo "Error: $BASE_ENV_FILE not found."
        exit 1
    fi

    cp "$BASE_ENV_FILE" "$ENV_FILE"

    sed -i "s/^CORE_TAG=.*/CORE_TAG=${VERSION}/" "$ENV_FILE"
    sed -i "s/^PREDICTION_TAG=.*/PREDICTION_TAG=${VERSION}/" "$ENV_FILE"
    sed -i "s/^MINER_SCHEDULER_TAG=.*/MINER_SCHEDULER_TAG=${VERSION}/" "$ENV_FILE"
    sed -i "s/^MINER_API_TAG=.*/MINER_API_TAG=${VERSION}/" "$ENV_FILE"
    sed -i "s/^DASHBOARD_TAG=.*/DASHBOARD_TAG=${VERSION}/" "$ENV_FILE"
    sed -i "s|^USER_VOLUME=.*|USER_VOLUME=${USER_VOLUME}|" "$ENV_FILE"
    if $WATCHTOWER; then
        sed -i "s/^ENABLE_WATCHTOWER=.*/ENABLE_WATCHTOWER=1/" "$ENV_FILE"
    else
        sed -i "s/^ENABLE_WATCHTOWER=.*/ENABLE_WATCHTOWER=0/" "$ENV_FILE"
    fi
    if [[ "$PROTOCOL" != "https" ]]; then
        sed -i "s/^CORE_AUTHCOOKIE_SECURE=.*/CORE_AUTHCOOKIE_SECURE=false/" "$ENV_FILE"
    else
        sed -i "s/^CORE_AUTHCOOKIE_SECURE=.*/CORE_AUTHCOOKIE_SECURE=true/" "$ENV_FILE"
    fi

}

runtime_generation() {
    cat <<EOF >"runtime-config.js"
window.runConfig = {
  apiBaseUrl: 'http://$IP:8080/api',
  socketUrl: 'http://$IP:9092/'
}
EOF
}

download_files() {
    REPO_URL="https://raw.githubusercontent.com/Arcan-Tech/impact-installation-script/master/"
    FILE1="docker-compose.yaml"
    FILE2=".base.env"

    OUTPUT_DIR="."

    echo "Fetching latest $FILE1 and $FILE2"
    wget -q "${REPO_URL}/${FILE1}" -O "${OUTPUT_DIR}/$(basename "$FILE1")"
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to download $FILE1"
        return 1
    fi

    wget -q "${REPO_URL}/${FILE2}" -O "${OUTPUT_DIR}/$(basename "$FILE2")"
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to download $FILE2"
        return 1
    fi
}

replace_passwords_in_env() {
    local env_file=".env"

    if [[ ! -f "$env_file" ]]; then
        echo "Error: $env_file not found."
        return 1
    fi

    # Backup the original .env file
    cp "$env_file" "${env_file}.bak"
    echo "Previous .env saved as as ${env_file}.bak"

    # Generate and replace all variables ending in PASSWORD
    while IFS= read -r line; do
        if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*PASSWORD= ]]; then
            var_name=$(echo "$line" | cut -d '=' -f 1)
            new_value=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)
            sed -i "s|^$var_name=.*|$var_name=$new_value|" "$env_file"
        fi
    done <"$env_file"
}

echo "This script will install the application using Docker."
echo "Make sure you have Docker installed and running."
read -p "Do you want to proceed? [y/n]: " PROCEED
if [[ "$PROCEED" != "y" ]]; then
    echo "Installation canceled."
    exit 0
fi

check_docker

if [ -f "$CONFIG_FILE" ]; then
    echo "A config.json file was found. Using existing credentials."
    echo "If you wish to logout simply delete the ${CONFIG_FILE} file"
else
    echo "No config.json file found. Creating a new one..."
    create_config_json
fi

configure_installation
download_files
env_generation
replace_passwords_in_env
runtime_generation

echo "Installation completed!"
echo "To start the application, run: ./run-impact.sh"
