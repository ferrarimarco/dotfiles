#!/usr/bin/env sh

# Wrappers for docker run commands

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

prune_container_runtime_environment() {
  docker system prune \
    --all \
    --force \
    --volumes
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

set_docker_interactive_and_tty_options() {
  _DOCKER_INTERACTIVE_TTY_OPTION=
  if [ -t 0 ]; then
    _DOCKER_INTERACTIVE_TTY_OPTION="-it"
  fi
}

update_container_image() {
  if [ "${UPDATE_CONTAINER_IMAGE:-}" = "true" ]; then
    docker pull "${1}"
  fi
}

#
# Container Aliases
#

ansible() {
  _CONTAINER_IMAGE_ID="ansible/ansible:${CONTAINER_IMAGE_VERSION:-"latest"}"
  update_container_image "${_CONTAINER_IMAGE_ID}"

  _CONTAINER_NAME="ansible"
  del_stopped "${_CONTAINER_NAME}"

  set_docker_interactive_and_tty_options

  # shellcheck disable=SC2086
  docker run \
    ${_DOCKER_INTERACTIVE_TTY_OPTION} \
    --name "${_CONTAINER_NAME}" \
    --rm \
    --volume "$(pwd)":/etc/ansible \
    --volume /etc/localtime:/etc/localtime:ro \
    "${_CONTAINER_IMAGE_ID}" \
    "$@"

  unset _CONTAINER_IMAGE_ID
  unset _CONTAINER_NAME
}

if ! is_command_available "gcloud"; then
  gcloud() {
    _CONTAINER_IMAGE_ID="gcr.io/google.com/cloudsdktool/cloud-sdk:${CONTAINER_IMAGE_VERSION:-"latest"}"
    update_container_image "${_CONTAINER_IMAGE_ID}"

    _CONTAINER_NAME="gcloud"
    del_stopped "${_CONTAINER_NAME}"

    set_docker_interactive_and_tty_options

    # shellcheck disable=SC2086
    docker run \
      ${_DOCKER_INTERACTIVE_TTY_OPTION} \
      --env CLOUDSDK_CONFIG=/config/gcloud \
      --name "${_CONTAINER_NAME}" \
      --rm \
      --volume "${GCLOUD_CONFIG_DIRECTORY}":/config/gcloud \
      --volume /etc/localtime:/etc/localtime:ro \
      "${_CONTAINER_IMAGE_ID}" \
      gcloud "$@"

    unset _CONTAINER_IMAGE_ID
    unset _CONTAINER_NAME
  }
fi

super_linter() {
  _CONTAINER_IMAGE_ID="ghcr.io/github/super-linter:${CONTAINER_IMAGE_VERSION:-"latest"}"
  update_container_image "${_CONTAINER_IMAGE_ID}"

  _CONTAINER_NAME="super_linter"
  del_stopped "${_CONTAINER_NAME}"

  set_docker_interactive_and_tty_options

  # shellcheck disable=SC2086
  docker run \
    ${_DOCKER_INTERACTIVE_TTY_OPTION} \
    --env ACTIONS_RUNNER_DEBUG="${ACTIONS_RUNNER_DEBUG:-"false"}" \
    --env ANSIBLE_DIRECTORY="${ANSIBLE_DIRECTORY:-"/ansible"}" \
    --env DEFAULT_WORKSPACE=/tmp/lint \
    --env DISABLE_ERRORS=false \
    --env ERROR_ON_MISSING_EXEC_BIT=true \
    --env IGNORE_GITIGNORED_FILES="true" \
    --env KUBERNETES_KUBEVAL_OPTIONS="--strict --ignore-missing-schemas --schema-location https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/" \
    --env LINTER_RULES_PATH="${LINTER_RULES_PATH:-"."}" \
    --env MULTI_STATUS=false \
    --env RUN_LOCAL=true \
    --env TEST_CASE_RUN="${TEST_CASE_RUN:-"false"}" \
    --env VALIDATE_ALL_CODEBASE=true \
    --env VALIDATE_JSCPD_ALL_CODEBASE="${VALIDATE_JSCPD_ALL_CODEBASE:-"true"}" \
    --name "${_CONTAINER_NAME}" \
    --rm \
    --volume "$(pwd)":/tmp/lint \
    --volume /etc/localtime:/etc/localtime:ro \
    --workdir /tmp/lint \
    "${_CONTAINER_IMAGE_ID}" \
    "$@"

  unset _CONTAINER_IMAGE_ID
  unset _CONTAINER_NAME
}
