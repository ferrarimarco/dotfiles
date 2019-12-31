#!/usr/bin/env bash

# shellcheck source=/dev/null
. "$HOME"/.shells/.all/environment.sh

# Set BASH_ENV so that if you use a shell as your login shell,
# and then start "bash" as a non-login non-interactive shell,
# the startup scripts will correctly run.
export BASH_ENV="$HOME"/.shells/.bash/environment.sh
