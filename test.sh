#!/bin/sh

set -euo pipefail

# find all executables and run `shellcheck`
find . -type f -iname "*.sh" -not -iname '*.git*' | sort -u | while read -r f; do
  if shellcheck "$f"; then
    echo "[OK]: sucessfully linted $f"
  else
    exit 1
  fi
done
