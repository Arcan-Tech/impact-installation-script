#!/bin/bash

# Detect the OS
if [[ "$(uname)" == "Darwin" ]]; then
    # Run macOS-specific command
    EFFECTIVE_USER=$(id -un)
    DOCKER_HOST=unix:///Users/$EFFECTIVE_USER/.docker/run/docker.sock MY_UID="$(id -u)" MY_GID="$(id -g)" docker --config ./docker-conf compose up $@
else
    MY_UID="$(id -u)" MY_GID="$(id -g)" docker --config ./docker-conf compose up $@
fi
