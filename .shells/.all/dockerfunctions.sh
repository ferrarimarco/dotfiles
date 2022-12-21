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

set_container_image_version() {
  if [ -n "${CONTAINER_IMAGE_VERSION-}" ]; then
    CONTAINER_IMAGE_ID="${CONTAINER_IMAGE_ID}:${CONTAINER_IMAGE_VERSION}"
    echo "Set container image version to ${CONTAINER_IMAGE_ID}"
  fi
}

set_interactive_docker_flags() {
  if [ -t 0 ]; then
    echo "--interactive --tty"
  fi
}

trim_string() {
  _INPUT="${1}"
  echo "${_INPUT}" | xargs
  unset _INPUT
}

update_container_image() {
  if [ "${UPDATE_CONTAINER_IMAGE-}" = "true" ]; then
    echo "Updating container image: ${CONTAINER_IMAGE_ID}"
    docker pull "${CONTAINER_IMAGE_ID}"
  fi
}

#
# Container Aliases
#

run_container() {
  CONTAINER_NAME="${1}"
  shift
  CONTAINER_IMAGE_ID="${1}"
  shift

  _DOCKER_FLAGS="${_DOCKER_FLAGS} $(set_interactive_docker_flags)"
  if [ -n "${ADDITIONAL_DOCKER_RUN_FLAGS-}" ]; then
    _DOCKER_FLAGS="${_DOCKER_FLAGS} ${ADDITIONAL_DOCKER_RUN_FLAGS}"
  fi
  _DOCKER_FLAGS="$(trim_string "${_DOCKER_FLAGS}")"
  del_stopped "${CONTAINER_NAME}"
  set_container_image_version
  update_container_image "${CONTAINER_IMAGE_ID}"
  echo ${_DOCKER_FLAGS}
  # shellcheck disable=SC2086
  docker run ${_DOCKER_FLAGS} \
    --name "${CONTAINER_NAME}" \
    --rm \
    --volume "$(pwd)":/workspace \
    --volume /etc/localtime:/etc/localtime:ro \
    "${CONTAINER_IMAGE_ID}" "$@"
  unset _DOCKER_FLAGS
}

ansible() {
  _DOCKER_FLAGS=
  run_container "ansible" "ansible/ansible" "$@"
}

gcloud() {
  _DOCKER_FLAGS="--env CLOUDSDK_CONFIG=/config/gcloud --volume ${GCLOUD_CONFIG_DIRECTORY}:/config/gcloud"
  run_container "gcloud" "gcr.io/google.com/cloudsdktool/cloud-sdk" "$@"
}

super_linter() {
  _DOCKER_FLAGS="--env ACTIONS_RUNNER_DEBUG=${ACTIONS_RUNNER_DEBUG:-"false"}"
  _DOCKER_FLAGS="${_DOCKER_FLAGS} --env ANSIBLE_DIRECTORY=\"${ANSIBLE_DIRECTORY:-"/ansible"}\""
  _DOCKER_FLAGS="${_DOCKER_FLAGS} --env DEFAULT_WORKSPACE=/workspace"
  _DOCKER_FLAGS="${_DOCKER_FLAGS} --env DISABLE_ERRORS=false"
  _DOCKER_FLAGS="${_DOCKER_FLAGS} --env ERROR_ON_MISSING_EXEC_BIT=true"
  _DOCKER_FLAGS="${_DOCKER_FLAGS} --env KUBERNETES_KUBEVAL_OPTIONS=\"--strict --ignore-missing-schemas --schema-location https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/\""
  _DOCKER_FLAGS="${_DOCKER_FLAGS} --env LINTER_RULES_PATH=\"${LINTER_RULES_PATH:-"."}\""
  _DOCKER_FLAGS="${_DOCKER_FLAGS} --env MULTI_STATUS=false"
  _DOCKER_FLAGS="${_DOCKER_FLAGS} --env RUN_LOCAL=true"
  _DOCKER_FLAGS="${_DOCKER_FLAGS} --env TEST_CASE_RUN=\"${TEST_CASE_RUN:-"false"}\""
  _DOCKER_FLAGS="${_DOCKER_FLAGS} --env VALIDATE_ALL_CODEBASE=true"
  _DOCKER_FLAGS="${_DOCKER_FLAGS} --env VALIDATE_JSCPD_ALL_CODEBASE=\"${VALIDATE_JSCPD_ALL_CODEBASE:-"true"}\""
  run_container "super_linter" "ghcr.io/github/super-linter" "$@"
}

terraform() {
  _DOCKER_FLAGS="--env ACTIONS_RUNNER_DEBUG=${ACTIONS_RUNNER_DEBUG:-"false"}"
  _DOCKER_FLAGS="${_DOCKER_FLAGS} --volume \"${GCLOUD_CONFIG_DIRECTORY}\":/root/.config/gcloud"
  _DOCKER_FLAGS="${_DOCKER_FLAGS} --workdir /workspace"
  run_container "terraform" "hashicorp/terraform" "$@"
}
