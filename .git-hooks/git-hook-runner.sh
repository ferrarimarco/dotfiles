#!/bin/sh

hook_type="$1"
shift

script_dir="$(dirname "$0")"
hooks_d_dir="${script_dir}/${hook_type}.d"

if [ -d "$hooks_d_dir" ]; then
  for hook_script in "$hooks_d_dir"/*; do
    if [ -f "$hook_script" ] && [ -x "$hook_script" ]; then
      "$hook_script" "$@"
      exit_code=$?
      if [ $exit_code -ne 0 ]; then
        exit $exit_code
      fi
    fi
  done
fi
