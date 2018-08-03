#!/bin/sh

set -euo pipefail

# find all executables and run `shellcheck`
find . -type f -not -path "*/\\.git/*" | sort -u | while read -r f; do
  if file "$f" | grep -q shell; then
    if shellcheck "$f"; then
      echo "[OK]: sucessfully linted $f"
    else
      exit 1
    fi
	fi
done
