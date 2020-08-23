#!/usr/bin/env sh

# Wrappers for docker run commands

DOCKER_FLAGS="-i"
DOCKER_FLAGS="$DOCKER_FLAGS --rm"
if [ -t 0 ]; then
    DOCKER_FLAGS="$DOCKER_FLAGS -t"
fi

#
# Helper Functions
#

del_stopped() {
    name=$1
    state=$(docker inspect --format "{{.State.Running}}" "$name" 2>/dev/null)

    if [ "$state" = "false" ]; then
        docker rm "$name"
    fi
    unset state
    unset name
}

relies_on() {
    for container in "$@"; do
        state=$(docker inspect --format "{{.State.Running}}" "$container" 2>/dev/null)

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
    docker run \
        $DOCKER_FLAGS \
        --net=host \
        -v /etc/localtime:/etc/localtime:ro \
        -v "$(pwd)":/etc/ansible \
        -v "${HOME}"/.ssh:/root/.ssh:ro \
        --name ansible \
        ferrarimarco/open-development-environment-ansible "$@"
}

changelog_generator() {
    del_stopped changelog-generator
    # shellcheck disable=SC2086
    docker run \
        $DOCKER_FLAGS \
        -v /etc/localtime:/etc/localtime:ro \
        -v "$(pwd)":/usr/local/src/your-app \
        --name changelog-generator \
        ferrarimarco/github-changelog-generator:1.15.0 "$@"
}

docker_clean() {
    del_stopped docker-clean
    # shellcheck disable=SC2086
    docker run \
        $DOCKER_FLAGS \
        -v /etc/localtime:/etc/localtime:ro \
        -v /var/run/docker.sock:/var/run/docker.sock \
        --name docker-clean \
        zzrot/docker-clean "$@"
}

jq() {
    del_stopped jq
    # shellcheck disable=SC2086
    docker run \
        $DOCKER_FLAGS \
        --name jq \
        stedolan/jq "$@"
}

inspec() {
    del_stopped inspec
    # shellcheck disable=SC2086
    docker run \
        $DOCKER_FLAGS \
        --net=host \
        -v /etc/localtime:/etc/localtime:ro \
        -v "$(pwd)":/share \
        -v "${HOME}"/.ssh:/root/.ssh:ro \
        --name inspec \
        chef/inspec "$@"
}

liquibase() {
    del_stopped liquibase
    # shellcheck disable=SC2086
    docker run \
        $DOCKER_FLAGS \
        -v /etc/localtime:/etc/localtime:ro \
        --name liquibase \
        ferrarimarco/liquibase "$@"
}

maven() {
    del_stopped maven
    # shellcheck disable=SC2086
    docker run \
        $DOCKER_FLAGS \
        -v /etc/localtime:/etc/localtime:ro \
        -v "${HOME}/.m2:/var/maven/.m2" \
        --name changelog-generator \
        -u "$(id -u)":"$(id -g)" \
        -e MAVEN_CONFIG=/var/maven/.m2 \
        maven \
        mvn -Duser.home=/var/maven "$@"
}

super_linter() {
    del_stopped super-linter
    # shellcheck disable=SC2086
    docker run \
        $DOCKER_FLAGS \
        --name super-linter \
        -v "$(pwd)":/workspace \
        -w="/workspace" \
        -e ACTIONS_RUNNER_DEBUG=true \
        -e DEFAULT_WORKSPACE=/workspace \
        -e DISABLE_ERRORS=false \
        -e LINTER_RULES_PATH=/workspace \
        -e MULTI_STATUS=false \
        -e RUN_LOCAL=true \
        -e VALIDATE_ALL_CODEBASE=true \
        github/super-linter:V3.8.0
}
