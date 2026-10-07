#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

REPOSITORY_ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
DEFAULT_SUPER_LINTER_VERSION="$(
  awk '/super-linter\/super-linter@/ {
    if ($NF ~ /^v/) print $NF
    else { split($0, a, "@"); print a[2] }
  }' "${REPOSITORY_ROOT}/.github/workflows/main.yml"
)"
SUPER_LINTER_CONTAINER_URL="${SUPER_LINTER_CONTAINER_URL:-"ghcr.io/super-linter/super-linter:${SUPER_LINTER_CONTAINER_IMAGE_VERSION:-"${DEFAULT_SUPER_LINTER_VERSION}"}"}"

DOCKER_FLAGS=(
  --rm
  --volume "${REPOSITORY_ROOT}:/tmp/lint"
  --volume /etc/localtime:/etc/localtime:ro
  --workdir /tmp/lint
)

if [ -t 0 ]; then
  DOCKER_FLAGS+=(
    --interactive
    --tty
  )
fi

LANGUAGES_WITH_FIX_MODE=(
  "ANSIBLE"
  "BIOME_LINT"
  "CLANG_FORMAT"
  "CSHARP"
  "CSS"
  "CSS_PRETTIER"
  "DOTNET_SLN_FORMAT_ANALYZERS"
  "DOTNET_SLN_FORMAT_STYLE"
  "DOTNET_SLN_FORMAT_WHITESPACE"
  "EDITORCONFIG"
  "ENV"
  "GITHUB_ACTIONS_ZIZMOR"
  "GO_MODULES"
  "GO"
  "GOOGLE_JAVA_FORMAT"
  "GROOVY"
  "GRAPHQL_PRETTIER"
  "HTML_PRETTIER"
  "JAVASCRIPT_ES"
  "JAVASCRIPT_PRETTIER"
  "JSON"
  "JSON_PRETTIER"
  "JSONC"
  "JSONC_PRETTIER"
  "JSX"
  "JSX_PRETTIER"
  "KOTLIN"
  "MARKDOWN"
  "MARKDOWN_PRETTIER"
  "NATURAL_LANGUAGE"
  "POWERSHELL"
  "PROTOBUF"
  "PYTHON_BLACK"
  "PYTHON_ISORT"
  "PYTHON_RUFF"
  "PYTHON_RUFF_FORMAT"
  "RUBY"
  "RUST_2015"
  "RUST_2018"
  "RUST_2021"
  "RUST_2024"
  "RUST_CLIPPY"
  "SCALAFMT"
  "SHELL_SHFMT"
  "SNAKEMAKE_SNAKEFMT"
  "SPELL_CODESPELL"
  "SQLFLUFF"
  "TERRAFORM_FMT"
  "TSX"
  "TYPESCRIPT_ES"
  "TYPESCRIPT_PRETTIER"
  "VUE"
  "VUE_PRETTIER"
  "YAML_PRETTIER"
)

format_prettier() {
  if [ "$#" -eq 0 ]; then
    set -- .
  fi

  docker run \
    "${DOCKER_FLAGS[@]}" \
    --entrypoint prettier \
    --user "$(id -u):$(id -g)" \
    "${SUPER_LINTER_CONTAINER_URL}" \
    --ignore-unknown \
    --write \
    "$@"
}

format_shfmt() {
  if [ "$#" -eq 0 ]; then
    set -- .
  fi

  docker run \
    "${DOCKER_FLAGS[@]}" \
    --entrypoint /bin/bash \
    --user "$(id -u):$(id -g)" \
    "${SUPER_LINTER_CONTAINER_URL}" \
    -c 'shfmt --find=0 "$@" | xargs -0 --no-run-if-empty shfmt --write' \
    _ \
    "$@"
}

lint_codebase() {
  docker run \
    "${DOCKER_FLAGS[@]}" \
    --env CREATE_LOG_FILE="${CREATE_LOG_FILE:-"false"}" \
    --env MULTI_STATUS="false" \
    --env RUN_LOCAL="true" \
    --env SAVE_SUPER_LINTER_OUTPUT="${SAVE_SUPER_LINTER_OUTPUT:-"false"}" \
    --env-file "${REPOSITORY_ROOT}/.github/linters/super-linter.env" \
    "$@" \
    "${SUPER_LINTER_CONTAINER_URL}"
}

fix_codebase() {
  local -a fix_flags=()
  local language
  for language in "${LANGUAGES_WITH_FIX_MODE[@]}"; do
    fix_flags+=(--env "FIX_${language}=true")
  done

  local exit_code=0
  lint_codebase "${fix_flags[@]}" "$@" || exit_code=$?

  docker run \
    "${DOCKER_FLAGS[@]}" \
    --entrypoint find \
    "${SUPER_LINTER_CONTAINER_URL}" \
    /tmp/lint -user 0 -exec chown "$(id -u):$(id -g)" {} +

  return "${exit_code}"
}

usage() {
  cat <<'EOF'
Usage: scripts/lint.sh [command] [args...]

Commands:
  lint                   Run Super-Linter on the codebase (default)
  fix                    Run Super-Linter in fix mode on the codebase
  format [paths...]      Run prettier and shfmt on paths (default: .)
  format-prettier [...]  Run prettier on paths (default: .)
  format-shfmt [...]     Run shfmt on paths (default: .)
  help                   Show this help message
EOF
}

main() {
  local command="${1:-lint}"
  if [ "$#" -gt 0 ]; then
    shift
  fi

  case "${command}" in
    lint)
      lint_codebase "$@"
      ;;
    fix)
      fix_codebase "$@"
      ;;
    format)
      format_prettier "$@"
      format_shfmt "$@"
      ;;
    format-prettier)
      format_prettier "$@"
      ;;
    format-shfmt)
      format_shfmt "$@"
      ;;
    help | -h | --help)
      usage
      ;;
    *)
      echo "Unknown command: ${command}" >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
