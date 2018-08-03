#!/bin/sh

set -euo pipefail

# running in alpine
# manually install needed package as I don't want to manage
# a custom shellcheck image
if which apk ; then
  apk add --update --no-cache \
    file
fi

# find all executables and run `shellcheck`
find . -type f -not -path "*/\.git/*" | sort -u | while read -r f; do
  echo "File: $f"
  if file "$f" | grep -q shell; then
    if shellcheck "$f"; then
      echo "[OK]: sucessfully linted $f"
    else
      exit 1
    fi
	fi
done
