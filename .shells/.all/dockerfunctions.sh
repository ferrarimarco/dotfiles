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
  CONTAINER_NAME="gcloud"
  del_stopped "${CONTAINER_NAME}"
  docker run ${DOCKER_TTY_OPTION} \
    -e CLOUDSDK_CONFIG=/config/gcloud \
    -i \
    --name "${CONTAINER_NAME}" \
    -v "${GCLOUD_CONFIG_DIRECTORY}":/config/gcloud \
    -v /etc/localtime:/etc/localtime:ro \
    gcr.io/google.com/cloudsdktool/cloud-sdk \
    gcloud "$@"
  unset GCLOUD_CONFIG_DIRECTORY
}

jq() {
  del_stopped jq
  docker run ${DOCKER_TTY_OPTION} \
    -i \
    --name jq \
    --rm \
    stedolan/jq "$@"
}

inspec() {
  del_stopped inspec
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
  docker run ${DOCKER_TTY_OPTION} \
    -i \
    --name "${CONTAINER_NAME}" \
    --rm \
    -v "$(pwd)":/tmp/lint \
    -e ACTIONS_RUNNER_DEBUG="${ACTIONS_RUNNER_DEBUG:-"false"}" \
    -e ANSIBLE_DIRECTORY="${ANSIBLE_DIRECTORY:-"/ansible"}" \
    -e DEFAULT_WORKSPACE=/tmp/lint \
    -e DISABLE_ERRORS=false \
    -e ERROR_ON_MISSING_EXEC_BIT=true \
    -e KUBERNETES_KUBEVAL_OPTIONS="--strict --ignore-missing-schemas --schema-location https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/" \
    -e LINTER_RULES_PATH=. \
    -e MULTI_STATUS=false \
    -e RUN_LOCAL=true \
    -e TEST_CASE_RUN="${TEST_CASE_RUN:-"false"}" \
    -e VALIDATE_ALL_CODEBASE=true \
    ghcr.io/github/super-linter "$@"
}

terraform() {
  del_stopped terraform
  docker run ${DOCKER_TTY_OPTION} \
    -i \
    --name terraform \
    --rm \
    -v "${GCLOUD_CONFIG_DIRECTORY}":/root/.config/gcloud \
    -v "$(pwd)":/workspace \
    -v /etc/localtime:/etc/localtime:ro \
    --volumes-from gcloud-config \
    -w "/workspace" \
    hashicorp/terraform "$@"
}
