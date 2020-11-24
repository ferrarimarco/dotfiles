#!/usr/bin/env bash

# ~/.bash_profile: executed by bash(1) for login shells.

# Ensure $HOME/.shells/.bash/environment.sh gets run first
# shellcheck source=/dev/null
. "$HOME"/.shells/.bash/environment.sh

# Prevent it from being run later, since we want to use $BASH_ENV for
# non-login non-interactive shells only.
# Don't export it, as we may have a non-login non-interactive shell as
# a child.
BASH_ENV=

# shellcheck source=/dev/null
. "$HOME"/.shells/.bash/login.sh

# Run this if is an interactive shell.
if [ "$PS1" ]; then
  # shellcheck source=/dev/null
  . "$HOME"/.shells/.bash/interactive.sh
fi
