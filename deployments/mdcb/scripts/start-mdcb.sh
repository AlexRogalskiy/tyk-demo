#!/bin/bash

source scripts/common.sh

check_docker_compose_version

command_docker_compose="$(generate_docker_compose_command) start tyk-mdcb"
eval $command_docker_compose
