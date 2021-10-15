#!/usr/bin/env sh

# Wrappers for docker run commands

DOCKER_TTY_OPTION=
if [ -t 0 ]; then
  DOCKER_TTY_OPTION="-t"
fi

#
# Helper Functions
#

del_stopped() {
  name=$1
  state="$(docker inspect --format "{{.State.Running}}" "$name" 2>/dev/null || echo "")"

  if [ "$state" = "false" ]; then
    docker rm "$name"
  fi
  unset state
  unset name
}

relies_on() {
  for container in "$@"; do
    state="$(docker inspect --format "{{.State.Running}}" "$container" 2>/dev/null || echo "")"

    if [ "$state" = "false" ] || [ "$state" = "" ]; then
      echo "$container is not running, starting it for you."
      $container
    fi
    unset state
  done
}

#
# Container Aliases
#

ansible() {
  del_stopped ansible
  # shellcheck disable=SC2086
  docker run ${DOCKER_TTY_OPTION} \
    -i \
    -v /etc/localtime:/etc/localtime:ro \
    -v "$(pwd)":/etc/ansible \
    --name ansible \
    --rm \
    ansible/ansible "$@"
}

gcloud() {
  docker run ${DOCKER_TTY_OPTION} \
    -i \
    --name gcloud-config \
    -u "$(id -u)":"$(id -g)" \
    -v /etc/localtime:/etc/localtime:ro \
    gcr.io/google.com/cloudsdktool/cloud-sdk \
    gcloud
}

jq() {
  del_stopped jq
  # shellcheck disable=SC2086
  docker run ${DOCKER_TTY_OPTION} \
    -i \
    --name jq \
    --rm \
    stedolan/jq "$@"
}

inspec() {
  del_stopped inspec
  # shellcheck disable=SC2086
  docker run ${DOCKER_TTY_OPTION} \
    -i \
    -v /etc/localtime:/etc/localtime:ro \
    -v "$(pwd)":/share \
    -v "${HOME}"/.ssh:/root/.ssh:ro \
    --name inspec \
    --rm \
    chef/inspec "$@"
}

super_linter() {
  CONTAINER_NAME="super_linter"
  del_stopped "${CONTAINER_NAME}"
  # shellcheck disable=SC2086
  docker run ${DOCKER_TTY_OPTION} \
    -i \
    --name "${CONTAINER_NAME}" \
    --rm \
    -v "$(pwd)":/workspace \
    -w "/workspace" \
    -e DEFAULT_WORKSPACE=/workspace \
    -e DISABLE_ERRORS=false \
    -e ERROR_ON_MISSING_EXEC_BIT=true \
    -e LINTER_RULES_PATH=. \
    -e MULTI_STATUS=false \
    -e RUN_LOCAL=true \
    -e VALIDATE_ALL_CODEBASE=true \
    ghcr.io/github/super-linter "$@"
}

terraform() {
  del_stopped terraform
  # shellcheck disable=SC2086
  docker run ${DOCKER_TTY_OPTION} \
    -i \
    --name terraform \
    --rm \
    -v "$(pwd)":/workspace \
    -v /etc/localtime:/etc/localtime:ro \
    -w "/workspace" \
    hashicorp/terraform "$@"
}
