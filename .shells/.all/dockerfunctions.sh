#!/usr/bin/env sh

# Wrappers for docker run commands

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

    docker run \
        --rm \
        -it \
        --net=host \
        -v /etc/localtime:/etc/localtime:ro \
        -v "$(pwd)":/etc/ansible \
        -v "${HOME}"/.ssh:/root/.ssh:ro \
        --name ansible \
        ferrarimarco/docker-ansible "$@"
}

changelog_generator() {
    del_stopped changelog-generator

    docker run -it --rm \
        -v /etc/localtime:/etc/localtime:ro \
        -v "$(pwd)":/usr/local/src/your-app \
        --name changelog-generator \
        ferrarimarco/github-changelog-generator:1.15.0 "$@"
}

docker_clean() {
    del_stopped docker-clean

    docker run --rm \
        -v /etc/localtime:/etc/localtime:ro \
        -v /var/run/docker.sock:/var/run/docker.sock \
        --name docker-clean \
        zzrot/docker-clean "$@"
}

dockerfile_lint() {
    del_stopped hadolint
    del_stopped dockerlint

    echo "Linting Dockerfiles from $(pwd)"
    find . -type f -iname "Dockerfile" | while read -r line; do
        echo "Linting $line"
        docker run -v "$(pwd)":/mnt --rm -w="/mnt" --name hadolint hadolint/hadolint hadolint "$line"
        docker run -v "$(pwd)":/mnt --rm -w="/mnt" --name dockerlint redcoolbeans/dockerlint "$line"
    done
}

jq() {
    del_stopped jq

    docker run \
        --rm \
        -i \
        --name jq \
        stedolan/jq "$@"
}

inspec() {
    del_stopped inspec

    docker run \
        --rm \
        -it \
        --net=host \
        -v /etc/localtime:/etc/localtime:ro \
        -v "$(pwd)":/share \
        -v "${HOME}"/.ssh:/root/.ssh:ro \
        --name inspec \
        chef/inspec "$@"
}

liquibase() {
    del_stopped liquibase
    docker run --rm \
        -v /etc/localtime:/etc/localtime:ro \
        --name liquibase \
        ferrarimarco/liquibase "$@"
}

maven() {
    del_stopped maven
    docker run --rm \
        -v /etc/localtime:/etc/localtime:ro \
        -v "${HOME}/.m2:/var/maven/.m2" \
        --name changelog-generator \
        -ti --rm -u "$(id -u)":"$(id -g)" \
        -e MAVEN_CONFIG=/var/maven/.m2 \
        maven \
        mvn -Duser.home=/var/maven "$@"
}

psscriptanalyzer() {
    del_stopped psscriptanalyzer

    docker run -it --rm \
        --name psscriptanalyzer \
        -v "$(pwd)":/usr/src:ro \
        mcr.microsoft.com/powershell \
        pwsh -command "Save-Module -Name PSScriptAnalyzer -Path .; Import-Module .\PSScriptAnalyzer; Invoke-ScriptAnalyzer -EnableExit -Path /usr/src -Recurse"

}

shellcheck() {
    del_stopped shellcheck

    docker run --rm -it \
        --name shellcheck \
        -v "$(pwd)":/usr/src:ro \
        ferrarimarco/shellcheck
}

super_linter() {
    del_stopped super-linter

    docker run --rm -it \
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
