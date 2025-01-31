#!/bin/bash
MY_UID="$(id -u)" MY_GID="$(id -g)" docker --config ./docker-conf compose up $@
